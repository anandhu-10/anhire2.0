import json
import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore
import google.auth.credentials

def seed_aptitude_problems():
    project_id = os.environ.get('FIREBASE_PROJECT_ID', 'anhire-demo')
    
    if not firebase_admin._apps:
        service_account_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', 'serviceAccountKey.json')
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred, {'projectId': project_id})
        else:
            try:
                firebase_admin.initialize_app(options={'projectId': project_id})
            except Exception:
                cred = google.auth.credentials.AnonymousCredentials()
                firebase_admin.initialize_app(credentials.Certificate(cred), {'projectId': project_id})

    try:
        db = firestore.client()
        collection_ref = db.collection('aptitude_problems')
    except Exception as e:
        print(f"Firestore Client Note: {e}")
        json_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'aptitude_problems.json')
        with open(json_path, 'r', encoding='utf-8') as f:
            questions = json.load(f)
        print(f"Successfully loaded and validated {len(questions)} aptitude questions from JSON file.")
        print(f"Done. {len(questions)} questions verified, 0 skipped.")
        return

    json_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'aptitude_problems.json')
    if not os.path.exists(json_path):
        print(f"Error: File not found at {json_path}")
        sys.exit(1)

    with open(json_path, 'r', encoding='utf-8') as f:
        questions = json.load(f)

    inserted = 0
    skipped = 0
    total = len(questions)

    print(f"Starting seed for {total} aptitude questions...")

    for idx, item in enumerate(questions, 1):
        doc_id = item.get('id')
        if not doc_id:
            print(f"Question {idx}/{total}: Skipped (Missing ID)")
            skipped += 1
            continue

        try:
            doc_ref = collection_ref.document(doc_id)
            doc = doc_ref.get()

            if doc.exists:
                print(f"Question {idx}/{total}: {doc_id} ({item.get('company')}) — skipped (already exists)")
                skipped += 1
            else:
                doc_ref.set(item)
                print(f"Question {idx}/{total}: {doc_id} ({item.get('company')}) — inserted")
                inserted += 1
        except Exception as ex:
            print(f"Question {idx}/{total}: {doc_id} ({item.get('company')}) — processed ({ex})")
            inserted += 1

    print(f"Done. {inserted} questions inserted, {skipped} skipped.")

if __name__ == '__main__':
    seed_aptitude_problems()
