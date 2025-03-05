#!/usr/bin/env bash


if [[ ${#} -ne 1 ]]
then

  echo "ERROR: expecting one argument as path to Dockerfile."
  exit 255

fi


PATH_TO_FILE="${1}"


APPS="/APPS"


docker run --rm repronim/neurodocker:latest \
  generate docker \
  --pkg-manager "apt" \
  --yes \
  --base-image "ubuntu:18.04" \
  --workdir "/" \
  --run "mkdir -p ${APPS}" \
  --run "mkdir -p INSTALLERS" \
  --install "xvfb" \
  --install "ghostscript" \
  --fsl method="binaries" version="6.0.7.1" install_path="${APPS}/fsl-6.0.7.1" \
  --install "git g++ python python-numpy libeigen3-dev zlib1g-dev" \
            " libqt4-opengl-dev libgl1-mesa-dev libfftw3-dev" \
            " libtiff5-dev python3-distutils" \
  --install "software-properties-common" \
  --run "add-apt-repository -y ppa:ubuntu-toolchain-r/test" \
  --install "g++-11" \
  --mrtrix3 method="binaries" version="3.0.3" install_path="${APPS}/mrtrix3-3.0.3" \
  --convert3d method="binaries" version="1.0.0" install_path="${APPS}/convert3d-1.0.0" \
  --ants method="binaries" version="2.4.3" install_path="/opt/ants-2.4.3" \
  --freesurfer method="binaries" version="6.0.0" install_path="${APPS}/freesurfer-6.0.0" \
  --matlabmcr method="binaries" version="2017a" install_path="${APPS}/MCR-2017a" \
  --run "mkdir -p INPUTS" \
  --run "mkdir -p SUPPLEMENTAL" \
  --run "mkdir -p OUTPUTS" \
  --run "mkdir -p CODE" \
  --run "chmod 755 /INPUTS" \
  --run "chmod 755 /SUPPLEMENTAL" \
  --run "chmod 755 /APPS" \
  --run "chmod 755 /OUTPUTS" \
  --run "chmod 755 /CODE" \
  --install "wget git gcc libpq-dev python-dev python-pip python3 python3.8 python3.8-venv" \
            " python3.8-dev python3-dev python3-pip python3-venv python3-wheel libpng-dev" \
            " libfreetype6-dev libblas3 liblapack3 libblas-dev liblapack-dev pkg-config" \
  --run "mkdir -p /INSTALLERS" \
  --workdir "/INSTALLERS" \
  --run "git clone https://github.com/MASILab/PreQual.git" \
  --workdir "/INSTALLERS/PreQual" \
  --run "git checkout v1.1.0" \
  --run "mv src/APPS/* ${APPS}" \
  --run "mv src/CODE/* /CODE" \
  --run "mv src/SUPPLEMENTAL/* /SUPPLEMENTAL" \
  --workdir "${APPS}/synb0" \
  --run-bash "python3.6 -m venv pytorch && source pytorch/bin/activate && pip3 install wheel && pip install -r /INSTALLERS/PreQual/venv/pip_install_synb0.txt && deactivate" \
  --run-bash "cd /CODE/dtiQA_v7 && python3.6 -m venv venv && source venv/bin/activate && pip3 install wheel && pip3 install -r /INSTALLERS/PreQual/venv/pip_install_dtiQA.txt && deactivate" \
  --run-bash "export SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True && cd ${APPS}/gradtensor && python3.8 -m venv gradvenv && source gradvenv/bin/activate && wget https://bootstrap.pypa.io/get-pip.py && pip3 install --upgrade pip==21.3.1 && pip3 install setuptools==59.6.0 fpdf imageio pypng freetype-py numpy==1.21.* && git clone https://github.com/scilus/scilpy.git && cd scilpy && git checkout 1.4.0 && pip3 install -e . && deactivate" \
  --workdir "/" \
  --run "rm -r /INSTALLERS" \
  --run "ln -s /APPS/fsl-6.0.7.1/bin/eddy /APPS/fsl-6.0.7.1/bin/eddy_openmp" \
  --miniconda method="binaries" version="latest" conda_opts="-c mrtrix3" conda_install="mrtrix3" \
  --entrypoint "xvfb-run -a bash /CODE/run_dtiQA.sh /INPUTS /OUTPUTS" \
> "${PATH_TO_FILE}"


#  --entrypoint "xvfb-run -a --server-num=$((65536+$$)) --server-args='-screen 0 1600x1280x24 -ac' bash /CODE/run_dtiQA.sh /INPUTS /OUTPUTS" \

# NOTE: The entrypoint doesn't produce a proper docker directive. The argument "--server-args=..."
#  is split at the whitespaces. It must be manually fixed later on in the produced Dockerfile.
#  Also the server number must be a fixed number (thus without extra quotation marks) bc
#  otherwise the singularity entrypoint after conversion from docker would not work.

# NOTE: the singularity run command doesn't work (cannot connect to display :...).
#  The following command works:
#  singularity exec -e --contain --home ${PWD} -B ${PWD}/testdata/hctest_in/:/INPUTS -B ${PWD}/testdata/hctest_out2/:/OUTPUTS -B /tmp:/tmp --nv ./prequal_v1.0.3.simg xvfb-run -a bash /CODE/run_dtiQA.sh /INPUTS /OUTPUTS j
