#!/bin/bash

# --- Configuration ---
# Set your desired CUDA version. Hugging Face with PyTorch typically works well with recent CUDA 12.x versions.
CUDA_VERSION="12.9"
# This URL is for CUDA 12.9.0 with driver version 575.51.03.
# ALWAYS VERIFY THIS URL on the NVIDIA CUDA Toolkit Archive for the latest stable 12.9.x version.
# https://developer.nvidia.com/cuda-toolkit-archive
CUDA_RUNFILE_URL="https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda_12.9.0_575.51.03_linux.run"
CUDA_INSTALL_DIR="/usr/local/cuda-${CUDA_VERSION}"

# Virtual environment settings
VENV_NAME="hf-llm-env" # Changed virtual environment name
VENV_PATH="$HOME/${VENV_NAME}"
PYTHON_VERSION="3.10" # Adjust if your Ubuntu uses a different default Python 3 version (e.g., 3.8, 3.9)

# --- Helper Functions ---
log_info() {
    echo -e "\n\e[1;34mINFO: $1\e[0m\n"
}

log_warn() {
    echo -e "\n\e[1;33mWARNING: $1\e[0m\n"
}

log_error() {
    echo -e "\n\e[1;31mERROR: $1\e[0m\n"
    exit 1
}

# --- 0. Initial System Setup ---
log_info "Starting system setup for Hugging Face LLM environment on a fresh Ubuntu install..."

log_info "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y || log_error "Failed to update/upgrade system packages."

log_info "Installing essential build tools, git, wget, curl, and python3-venv..."
sudo apt install -y build-essential dkms wget curl git python3-pip python3-venv || log_error "Failed to install essential packages."

# --- 1. NVIDIA Driver Installation (Recommended for fresh installs) ---
log_warn "--------------------------------------------------------------------------------"
log_warn "NVIDIA Driver Installation:"
log_warn "This is a FRESH Ubuntu install. It is HIGHLY RECOMMENDED to install the NVIDIA driver first."
log_warn "This script will attempt to install the recommended driver via 'ubuntu-drivers autoinstall'."
log_warn "--------------------------------------------------------------------------------"
read -p "Do you want to install recommended NVIDIA drivers? (y/N): " install_driver_choice
if [[ "$install_driver_choice" =~ ^[Yy]$ ]]; then
    log_info "Installing recommended NVIDIA drivers..."
    sudo ubuntu-drivers autoinstall || log_error "Failed to install NVIDIA drivers."
    log_info "NVIDIA drivers installed. A reboot is required for changes to take effect."
    log_info "The script will now prompt for a reboot. Please RE-RUN THIS SCRIPT after your system restarts."
    read -p "Press Enter to reboot now..."
    sudo reboot
    exit 0 # Exit script after reboot prompt, user must re-run
else
    log_warn "Skipping NVIDIA driver installation. This is NOT recommended for a fresh install."
    log_warn "Proceeding without a confirmed NVIDIA driver installation may lead to issues."
    read -p "Are you sure you want to proceed without installing NVIDIA drivers? (y/N): " confirm_no_driver
    if ! [[ "$confirm_no_driver" =~ ^[Yy]$ ]]; then
        log_error "Aborting script. Please run again and install NVIDIA drivers."
    fi
fi

# --- 2. Install CUDA 12.9 Toolkit ---
log_info "Downloading CUDA ${CUDA_VERSION} runfile from ${CUDA_RUNFILE_URL}..."
cd /tmp # Download to a temporary directory
wget "${CUDA_RUNFILE_URL}" -O "cuda_${CUDA_VERSION}_linux.run" || log_error "Failed to download CUDA ${CUDA_VERSION} runfile. Check URL and internet connection."

log_info "Making CUDA runfile executable..."
chmod +x "cuda_${CUDA_VERSION}_linux.run" || log_error "Failed to make CUDA runfile executable."

log_warn "--------------------------------------------------------------------------------"
log_warn "STARTING CUDA ${CUDA_VERSION} INSTALLER - USER INTERACTION REQUIRED!"
log_warn "********************************************************************************"
log_warn "* IMPORTANT: When prompted by the installer, you MUST DESELECT THE 'Driver' COMPONENT. *"
log_warn "*            Only install the CUDA Toolkit.                                    *"
log_warn "*            Use arrow keys to navigate, Spacebar to select/deselect, Enter to confirm. *"
log_warn "********************************************************************************"
read -p "Press Enter to start the CUDA installer. Follow the instructions above carefully..."

# Run the installer. This will be interactive.
sudo "./cuda_${CUDA_VERSION}_linux.run"

if [ ! -d "${CUDA_INSTALL_DIR}" ]; then
    log_error "CUDA ${CUDA_VERSION} installation directory not found at ${CUDA_INSTALL_DIR}. Installation might have failed or path is different. Please check /var/log/cuda-installer.log"
fi
log_info "CUDA ${CUDA_VERSION} Toolkit installed successfully to ${CUDA_INSTALL_DIR}."

# --- 3. Configure CUDA Environment Variables ---
log_info "Configuring CUDA environment variables in ~/.bashrc..."
{
    echo ""
    echo "# NVIDIA CUDA Toolkit ${CUDA_VERSION}"
    echo "export PATH=${CUDA_INSTALL_DIR}/bin\${PATH:+:\${PATH}}"
    echo "export LD_LIBRARY_PATH=${CUDA_INSTALL_DIR}/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
} >> ~/.bashrc

source ~/.bashrc
log_info "CUDA environment variables set and sourced for current session."
log_info "Please open a new terminal or run 'source ~/.bashrc' for changes to take full effect."

# --- 4. Create and Activate Python Virtual Environment ---
log_info "Creating Python virtual environment '${VENV_NAME}' at ${VENV_PATH}..."
python${PYTHON_VERSION} -m venv "$VENV_PATH" || log_error "Failed to create virtual environment. Ensure python${PYTHON_VERSION} is installed."

log_info "Activating virtual environment..."
source "$VENV_PATH/bin/activate" || log_error "Failed to activate virtual environment. Check path: $VENV_PATH"

log_info "Upgrading pip in virtual environment..."
pip install --upgrade pip || log_error "Failed to upgrade pip."

# --- 5. Install PyTorch and Hugging Face Libraries ---
log_info "Installing PyTorch with CUDA 12.x support (using cu121 wheel)..."
# The PyTorch wheel for cu121 is generally compatible with CUDA 12.9.
# Check https://pytorch.org/get-started/locally/ for the most up-to-date command.
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 || log_error "Failed to install PyTorch. Check PyTorch website for correct CUDA 12.x command."
log_info "PyTorch installed."

log_info "Installing Hugging Face Transformers and Accelerate..."
pip install transformers accelerate || log_error "Failed to install Hugging Face libraries."
log_info "Hugging Face Transformers and Accelerate installed."

# --- 6. Install Jupyter Notebook ---
log_info "Installing Jupyter Notebook and ipykernel..."
pip install jupyter ipykernel || log_error "Failed to install Jupyter and ipykernel."

log_info "Adding virtual environment to Jupyter kernels..."
python -m ipykernel install --user --name="${VENV_NAME}" --display-name="${VENV_NAME} (Python ${PYTHON_VERSION})" || log_error "Failed to add Jupyter kernel."
log_info "Jupyter Notebook and kernel configured."

# --- 7. Verification ---
log_info "--------------------------------------------------------------------------------"
log_info "SETUP COMPLETE! Performing final verifications..."
log_info "--------------------------------------------------------------------------------"

log_info "Checking nvcc version:"
nvcc --version || log_warn "nvcc command failed. Check CUDA installation and PATH."

log_info "Checking PyTorch CUDA availability (inside venv):"
python -c "import torch; print('PyTorch CUDA available:', torch.cuda.is_available()); print('PyTorch CUDA version:', torch.version.cuda)" || log_warn "PyTorch CUDA check failed."

log_info "Checking Hugging Face Transformers import (inside venv):"
python -c "from transformers import pipeline; print('Hugging Face Transformers import successful')" || log_warn "Hugging Face Transformers import failed."

log_info "--------------------------------------------------------------------------------"
log_info "All steps attempted. Please review the output for any warnings or errors."
log_info "To use your setup:"
log_info "1. Open a new terminal."
log_info "2. Activate your virtual environment: \e[1;32msource ${VENV_PATH}/bin/activate\e[0m"
log_info "3. To start Jupyter Notebook: \e[1;32mjupyter notebook\e[0m"
log_info "Your virtual environment is also available as a Jupyter kernel named '${VENV_NAME} (Python ${PYTHON_VERSION})'."
log_info "--------------------------------------------------------------------------------"

log_info "Script finished."