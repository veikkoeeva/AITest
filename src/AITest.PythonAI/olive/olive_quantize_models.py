import os
import sys
import json
import urllib.request
from typing import Dict, Any
from olive.workflows import run as olive_run


def download_model(model_url: str, model_dir: str, model_name: str) -> str:
    """
    Downloads a model from the given URL if it doesn't already exist locally.

    This function checks if the model file already exists in the specified directory.
    If not, it creates the directory (if necessary) and downloads the model from the provided URL.
    The model is saved using the specified file name.

    Args:
        model_url (str): The URL from which to download the model.
        model_dir (str): The directory where the model will be saved.
        model_name (str): The name of the model file to be saved.

    Returns:
        str: The absolute path to the downloaded (or existing) model file.

    Example:
        model_url = "https://example.com/model.onnx"
        model_dir = "artifacts/models/resnet50"
        model_name = "resnet50-v2-7.onnx"
        model_path = download_model(model_url, model_dir, model_name)
        print(f"Model is saved at: {model_path}")
    """

    model_path: str = os.path.join(model_dir, model_name)
    os.makedirs(model_dir, exist_ok=True)

    if not os.path.exists(model_path):
        print(f"Downloading the model from {model_url}...")
        urllib.request.urlretrieve(model_url, model_path)
        print(f"Model downloaded to {model_path}")
    else:
        print(f"Model already exists at {model_path}")

    return model_path


def run_olive_workflow(config_path: str) -> None:
    """
    Executes the Olive workflow using the specified configuration file.

    This function takes the path to a JSON configuration file, ensures its existence,
    and then runs the Olive workflow with the specified configuration. It also prints
    the contents of the configuration for verification.

    Args:
        config_path (str): The path to the Olive workflow configuration file. 
            This should be a JSON file containing the required settings.

    Raises:
        FileNotFoundError: If the configuration file does not exist at the specified path.
        json.JSONDecodeError: If the configuration file is not a valid JSON.

    Example:
        config_path = "config/olive_quantize_cpu_to_fp16.json"
        run_olive_workflow(config_path)
        
    Side Effects:
        - Converts the config path to an absolute path.
        - Prints the configuration contents in a formatted manner.
        - Executes the Olive workflow using `olive_run`.

    Note:
        Ensure that the Olive workflow package is correctly installed and configured
        before running this function.
    """

    # Ensure the path is absolute.
    config_path = os.path.abspath(config_path)
    print(f"Running Olive workflow with config: {config_path}")

    # Check if the file exists.
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"❌ Configuration file not found: {config_path}")
    
    config_data: Dict[str, Any]
    with open(config_path, "r") as f:
        config_data = json.load(f)
        print(json.dumps(config_data, indent=4))

    olive_run(config_path)
    print("✅ Olive workflow completed.")


if __name__ == "__main__":
    print(f"Python executable: {sys.executable}")
    print(f"Current working directory: {os.getcwd()}")
    
    model_url: str = "https://github.com/onnx/models/raw/main/validated/vision/classification/resnet/model/resnet50-v2-7.onnx"
    model_dir: str = "artifacts/models/resnet50"
    model_name: str = "resnet50-v2-7.onnx"

    # Get the absolute path of the config file.
    script_dir: str = os.path.dirname(os.path.abspath(__file__))  
    olive_config_path: str = os.path.join(script_dir, "olive_quantize_cpu_to_fp16.json")

    print(f"Using Olive config path: {olive_config_path}")

    # Step 1: Download the model.    
    download_model(model_url, model_dir, model_name)

    # Step 2: Run the Olive workflow.
    run_olive_workflow(olive_config_path)
