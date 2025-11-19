const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateNotifications() {
  const notificationsRef = db.collection('notifications');
  const snapshot = await notificationsRef.get();

  if (snapshot.empty) {
    console.log('No notifications found.');
    return;
  }

  let migratedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    // Determine receiver UID
    const toUid = data.uid || data.to;
    if (!toUid) {
      console.log(`Skipping notification ${doc.id} because it has no receiver UID`);
      continue;
    }

    // Ensure required fields
    const notificationData = {
      uid: toUid,
      to: toUid,
      fromUid: data.fromUid || data.from || '',
      fromName: data.fromName || 'Someone',
      type: data.type || (data.status ? `request_${data.status}` : 'unknown'),
      requestId: data.requestId || doc.id,
      message: data.message || '',
      timestamp: data.timestamp || admin.firestore.FieldValue.serverTimestamp(),
      seen: data.seen !== undefined ? data.seen : false
    };

    // Write into the per-user subcollection
    await db
      .collection('notifications')
      .doc(toUid)
      .collection('notifications')
      .doc(doc.id) // keep the same document ID
      .set(notificationData);

    // Optionally delete the old top-level document
    await doc.ref.delete();

    console.log(`Migrated notification ${doc.id} to user ${toUid}`);
    migratedCount++;
  }

  console.log(`Finished migration. Total migrated: ${migratedCount}`);
}

migrateNotifications().catch(console.error);
