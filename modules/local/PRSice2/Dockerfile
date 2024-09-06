FROM --platform=linux/amd64 continuumio/miniconda3:24.5.0-0


RUN conda install r-base -c conda-forge

RUN conda install wget -c conda-forge

RUN wget https://github.com/choishingwan/PRSice/releases/download/2.3.5/PRSice_linux.zip

RUN unzip PRSice_linux.zip
