import os
import sys
import json
import urllib.request
from olive.workflows import run as olive_run

def download_model(model_url, model_dir, model_name):        
    model_path = os.path.join(model_dir, model_name)
    os.makedirs(model_dir, exist_ok=True)

    if not os.path.exists(model_path):
        print(f"Downloading the model from {model_url}...")
        urllib.request.urlretrieve(model_url, model_path)
        print(f"Model downloaded to {model_path}")
    else:
        print(f"Model already exists at {model_path}")

    return model_path

def run_olive_workflow(config_path) -> None:
    
    # Ensure the path is absolute.
    config_path = os.path.abspath(config_path)
    print(f"Running Olive workflow with config: {config_path}")

    # Check if the file exists.
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"❌ Configuration file not found: {config_path}")
    
    with open(config_path, "r") as f:
        config_data = json.load(f)
        print(json.dumps(config_data, indent=4))

    olive_run(config_path)
    print("✅ Olive workflow completed.")

if __name__ == "__main__":
    print(f"Python executable: {sys.executable}")
    print(f"Current working directory: {os.getcwd()}")

    model_url = "https://github.com/onnx/models/raw/main/validated/vision/classification/resnet/model/resnet50-v2-7.onnx"
    model_dir = "artifacts/models/resnet50"
    model_name = "resnet50-v2-7.onnx"

    # Get the absolute path of the config file.
    script_dir = os.path.dirname(os.path.abspath(__file__))  
    olive_config_path = os.path.join(script_dir, "olive_quantize_cpu_to_fp16.json")

    print(f"Using Olive config path: {olive_config_path}")

    # Step 1: Download the model.
    download_model(model_url, model_dir, model_name)

    # Step 2: Run the Olive workflow.
    run_olive_workflow(olive_config_path)