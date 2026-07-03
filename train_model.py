import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
import pickle
import os

def main():
    base_path = os.path.dirname(os.path.abspath(__file__))
    print("Loading data...")
    file_path = os.path.join(base_path, "lupus_data_processed.csv")
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found.")
        return

    data = pd.read_csv(file_path, index_col=0)
    
    print(f"Data loaded with shape: {data.shape}")
    X = data.drop('Diagnosis', axis=1)
    y = data['Diagnosis']

    print("Encoding labels...")
    le = LabelEncoder()
    y_encoded = le.fit_transform(y)

    print("Training RandomForest model...")
    # Using small estimators for quick compilation, though usually we'd use 100+
    model = RandomForestClassifier(n_estimators=20, random_state=42)
    model.fit(X, y_encoded)
    
    print("Calculating feature medians...")
    feature_medians = X.median().to_dict()
    feature_names = list(X.columns)

    print("Saving model and features to disk...")
    pickle.dump(model, open(os.path.join(base_path, "lupus_classifier.pkl"), "wb"))
    pickle.dump(le, open(os.path.join(base_path, "label_encoder.pkl"), "wb"))
    pickle.dump(feature_names, open(os.path.join(base_path, "feature_names.pkl"), "wb"))
    pickle.dump(feature_medians, open(os.path.join(base_path, "feature_medians.pkl"), "wb"))

    print("Model training complete. Files saved.")

if __name__ == "__main__":
    main()
