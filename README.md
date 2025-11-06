# To setup notebooks on Nvidia gpu based servers for testing

This set of notebooks gives examples of how to run Jupyter Notebooks on NVIDA based gpus.

It uses Hugging Face models, Cuda, and Pytroch to server LLM's or other models.

## Perform the following steps

- Git clone the repo
- chmod +x ~/setup_notebooks.sh
- Run setup.sh
- CD to your directory and run jupyter notebook --ip 0.0.0.0 --port 8888