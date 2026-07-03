import streamlit as st
import pandas as pd
import pickle
import os

st.set_page_config(page_title="Lupus Classifier", layout="wide")

st.title("🩺 Lupus Classifier Dashboard")
st.write("Upload a CSV file containing patient gene expression data to predict Lupus diagnosis.")

@st.cache_resource
def load_assets():
    base_path = os.path.dirname(os.path.abspath(__file__))
    model = pickle.load(open(os.path.join(base_path, 'lupus_classifier.pkl'), 'rb'))
    le = pickle.load(open(os.path.join(base_path, 'label_encoder.pkl'), 'rb'))
    feature_names = pickle.load(open(os.path.join(base_path, 'feature_names.pkl'), 'rb'))
    feature_medians = pickle.load(open(os.path.join(base_path, 'feature_medians.pkl'), 'rb'))
    return model, le, feature_names, feature_medians

try:
    with st.spinner("Loading model assets..."):
        model, le, feature_names, feature_medians = load_assets()
    st.success("✅ Model loaded successfully!")
except Exception as e:
    st.error(f"Error loading model assets: {e}")
    st.info("Please run `train_model.py` first to generate the necessary `.pkl` files.")
    st.stop()

st.markdown("### 📥 Input Data")
uploaded_file = st.file_uploader("Choose a CSV file", type="csv")

if uploaded_file is not None:
    data = pd.read_csv(uploaded_file, index_col=0)
    st.write(f"Loaded {len(data)} samples.")
    
    # Align features
    missing_cols = set(feature_names) - set(data.columns)
    if missing_cols:
        st.warning(f"Filling {len(missing_cols)} missing columns with medians.")
        for c in missing_cols:
            data[c] = feature_medians.get(c, 0)
            
    X = data[feature_names]
    
    if st.button("🚀 Predict"):
        with st.spinner("Making predictions..."):
            preds = model.predict(X)
            pred_labels = le.inverse_transform(preds)
            
            result_df = pd.DataFrame({
                'Sample': data.index.tolist() if not data.index.empty else [f"Sample_{i}" for i in range(len(preds))],
                'Prediction': pred_labels
            })
            
            st.markdown("### 📊 Predictions")
            st.dataframe(result_df, use_container_width=True)
            
            # Allow downloading results
            csv = result_df.to_csv(index=False)
            st.download_button(
                label="📁 Download Predictions as CSV",
                data=csv,
                file_name='lupus_predictions.csv',
                mime='text/csv'
            )
else:
    st.info("Awaiting CSV file upload...")
