# To setup notebooks on Nvidia gpu based servers for testing

This set of notebooks gives examples of how to run Jupyter Notebooks on NVIDA based gpus.

It uses Hugging Face models, Cuda, and Pytroch to server LLM's or other models.

## Perform the following steps

- Git clone the repo
- Update the permissions on the setup file ```chmod +x ~/setup_notebooks.sh```
- Run setup_notebooks.sh
- Reboot and check the NVIDIA software ```nvidia-smi```
- Install Nvidia cuda toolkit
  ```cd /tmp ```
  ```rm -f cuda_12.9.0_575.51.03_linux.run # Remove old potentially corrupted file```
  ```wget https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda_12.9.0_575.51.03_linux.run -O cuda_12.9_linux.run```
  ```chmod +x cuda_12.9_linux.run```
  ```sudo /tmp/cuda_12.9_linux.run # Only install the toolkit!!!!!```
- CD to Nvidia-notebooks directory
- Setup Python virtual environment - ```python3.10 -m venv ~/hf-llm-env```
- Activiate the virtual environement - ```source ~/hf-llm-env/bin/activate```
- Update pip ```pip install --upgrade pip```
- Install requirements ```pip install -r ~/my_llm_project/requirements.txt```
- Add virtual environment to Jupyer Kernel - ```python -m ipykernel install --user --name="hf-llm-env" --display-name="hf-llm-env (Python 3.10)"```
- CD to your directory and run ```jupyter notebook --ip 0.0.0.0 --port 8888```
