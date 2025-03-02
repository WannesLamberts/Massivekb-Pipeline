
  
  
# MassiveKB pipeline  
## Introduction  
MassiveKB is a database that contains a lot of PSMs; however, due to the dataset's large size, these PSMs are not readily available for direct download. This Nextflow-based project provides a streamlined pipeline for compiling the [Human HCD Spectral](https://massive.ucsd.edu/ProteoSAFe/status.jsp?task=82c0124b6053407fa41ba98f53fd8d89) data on MassiveKB in a user-friendly manner. The resulting dataset includes 185 million PSMs at 1% FDR, generated using MSGF+.  
  
## Table of Contents  
- [MassiveKB pipeline](#massivekb-pipeline)  
  - [Introduction](#introduction)  
  - [Pipeline Workflow](#pipeline-workflow)  
  - [Installation](#installation)  
  - [Usage locally](#usage-locally)  
    - [Overview](#overview)  
    - [Example run: Complete workflow](#example-run-complete-workflow)  
    - [Example run: Separated workflow](#example-run-separated-workflow)  
    - [Configuration options](#configuration-options)  
      - [List of Configurable Parameters](#list-of-configurable-parameters)  
      - [Special Flags](#special-flags)  
  - [Usage Slurm (for HPC)](#usage-slurm-for-hpc)  
  - [Output](#output)  
  -  [Recommendations and expected runtime](##Recommendations\ and\ expected\ runtime )
  - [Extra functionality](##extra\ functionality) 
	  - [Simple run](###Simple\ run) 
	  - [Concatenate](###concatenate)
  - [Pipeline Structure](#pipeline-structure)  
  - [Acknowledgement](#acknowledgement)  
  - [Disclaimer](#disclaimer)  
  - [Contact](#contact)  
  
  
  
## Pipeline Workflow  
  
  
This section describes the workflow for manually compiling the dataset, as the pipeline follows the same steps. For additional details, refer to the well-documented code.  
  
This pipeline is designed to collect the dataset [Human HCD Spectral Library](https://massive.ucsd.edu/ProteoSAFe/status.jsp?task=82c0124b6053407fa41ba98f53fd8d89) along with its metadata, which can be accessed [here](https://massive.ucsd.edu/ProteoSAFe/result.jsp?task=82c0124b6053407fa41ba98f53fd8d89&view=candidate_library_spectra). The provided metadata file contains only 30 million PSMs, whereas the full set of 185 million PSMs can be retrieved from multiple mzTab files on MassIVE.  
  
To obtain the complete dataset, first extract all unique search task identifiers from the "proteosafe_task" column in the downloaded metadata TSV file. Then, use these identifiers to construct URLs in the following format:   
  
`https://proteomics2.ucsd.edu/ProteoSAFe/result.jsp?task=[ID]&view=view_result_list`   
(replacing `[ID]` with the extracted task identifiers).  
  
However, the mzTab PSMs are missing certain information, such as retention time. To retrieve this data, the corresponding mzML and mzXML files must be parsed, and the extracted information should then be merged with the PSMs in the mzTab file. 
  
  
## Installation  
  
Make sure the following are installed on your system:  
  
- Nextflow  
- Docker or Apptainer (Note: This is optional, but without it, you'll need to manually install the dependencies from the requirements.txt file)  
  
The only installation step is to clone the GitHub repository:  
 ```bash  
 git clone https://github.com/WannesLamberts/Massivekb-Pipeline.git  
 ```
 ## Usage  locally  
### Overview  
  
  
Here are two main workflows for running the pipeline:  
  
1.  **Download Workflow**: This approach begins by downloading the metadata file to generate aquire the unique task and then create the PSMs from these tasks. However, since the metadata file includes over 7000 tasks, the process can be time-consuming.  
      
2.  **Run from Tasks Workflow**: This method starts with an input TSV file that lists the tasks to be executed. You can find all unique tasks in `input_files/all_tasks.tsv`, while a smaller subset is available in `input_files/first100.tsv`. If you prefer to generate all the tasks yourself, you can run:  
	  ```bash  
	  nextflow run main.nf -c config_files/local.config -entry download_tasks -with-docker  
	 ```  
	 This command will produce the same TSV file as `input_files/all_tasks.tsv`.  This workflow allows greater control over task selection and execution volume.  
  
Additionally, two workflow variants have been implemented for when the extra information from mzML/mzXML files arent needed. These variants collect data solely from the mzTab file, skipping the mzML/mzXML files. As a result, these workflows are considerably faster while still providing charge and m/z values in the rows. These variants are explained in section    [Extra functionality](#extra\ functionality)  .

  
  
### Example run Download workflow  
 ```bash  
 nextflow run main.nf -c config_files/local.config -entry download_and_run_tasks -with-docker  
 ```
 ### Example run Run from Tasks workflow  
 ```bash  
 nextflow run main.nf -c config_files/local.config -entry run_tasks --input input_files/first_100.tsv -with-docker  
 ```  
 You can change the input file as you like containing the tasks you want to run.  

  ### Configuration options  
  
Several configuration parameters can be used to customize the pipeline execution. These parameters can be added to the run command with `--<param_name> <value>`. For example, setting the `input_file` to `tasks.tsv` and `out_dir` to `out` will specify where to load the tasks and write the output.  
  
bash  
 ```bash  
 nextflow run main.nf -c config_files/local.config -entry run_tasks --input tasks.tsv --out_dir out -with-docker  
 ```
 Alternatively, you can modify these parameters directly in the `config_files/local.config` file.  
  
#### List of Configurable Parameters  
  
-   **dataset_link**: The link to download the massivekb metadata. Defaults to the original link.  
-   **out_dir**: Directory where results are saved. Default is `results`.  
-   **input**: Path to input if a workflow requires input.  
-   **cpu_tasks**: Maximum CPUs a process can use. Default is 1.  
-   **memory**: Maximum memory a process can use. Default is 4GB.  
-   **max_processes**: Maximum number of processes that can run in parallel. Default is 10.  
-   **work_dir**: Directory for temporary results and debugging info. Default is `work`.  
-   **testing**: If set to true, intermediate downloaded results are kept.  
  
#### Special Flags  
-   **-with-docker**: Uses Docker containers for running processes. The required image will be automatically pulled from Docker Hub.  
-   **-with-apptainer**: Uses Apptainer containers for running processes. The required image will be automatically pulled from Docker Hub.  
-   **-with-tower**: Connects the run to Seqera for an overview of the pipeline execution. Requires a Seqera account and exported environment variables. A tutorial is available [here](https://training.nextflow.io/2.0/basic_training/seqera_platform/).  
-   **--with-trace**: Adds a trace file to the Nextflow run.  
-   **-entry <workflow>**: Runs a specific workflow. A list of available workflows can be found in `main.nf`.  
-   **-c <config_file_name>**: Specifies the configuration file for Nextflow. Instructions for using the `slurm.config` file are provided in the next section.  
  
  ## Usage Slurm (for HPC)  
The pipeline can also be executed using a Slurm executor, which creates Slurm tasks for all processes. This allows the pipeline to run efficiently on a supercomputer. To use Slurm, simply add `-c config_files/slurm.config` to the Nextflow command.  
  
Other than this, the execution remains the same as described in [Usage locally](##Usage\ locally), with one key difference: the `cpu_tasks` and `memory` parameters are removed, and the `clusterOptions` parameter is introduced. The `clusterOptions` parameter is used to define Slurm-specific settings for processes. For example, using `--clusterOptions "-t 24:00:00 -c 1"` sets the number of CPUs per process to 1 and applies a time limit of 24 hours per process.  
  
Examples of Slurm-based runs can be found in the `slurm_example_scripts` directory:  
  
-  `run_all.slurm` – A complete run from start to output.  
-  `run_tasks.slurm` – A run that takes as input the first 100 tasks  
-  `run_all_simple.slurm` – A complete simple run  
-  `run_tasks_simple.slurm` – A simple run that takes as input the first 100 tasks  
  
All these examples also have an example with _with_tower behind the name, this is an example where seqera is used to generate an interface.  
     
  ## Output  
The output is stored by default in the `results` folder. Inside this folder, there is a `psms` directory containing TSV files for each task, where each file holds the PSMs. The columns in these files do not have headers to facilitate easy concatenation. The column order is: `task_id`, `dataset`,`filename`,`scan_nr`, `sequence`, `charge`,`mz` and `RT`.   This output can be easily put together by running the workflow explained in [Extra functionality](#extra\ functionality)  .
  
Additionally, the `results` folder includes:  
  
-   `successful_task.tsv`: A file listing all successfully completed tasks.  
-   `failed_processes.tsv`: A file tracking failed processes along with their respective task IDs and exit codes.  
-  `trace.txt`: If specified a trace file holding information about the processes.  
  
The possible exit codes are:  
  
-   **186**: No mztab file found for the task ID.  
-   **51**: An issue occurred while collecting mztab PSMs, often due to an **Out of Memory (OOM)** error.  
-   **58**: An error occurred while downloading the mzML/mzXML files.  
-  **1**: An unknown error occured, debug this by looking at `scratch/command.err`   
  
  
## Recommendations and expected runtime  
As mentioned earlier, it’s more efficient to run smaller batches of tasks using the "Run From Tasks" workflow. It's advised to allocate 4GB of memory and 1 CPU for each task, and limit the concurrent processes to 10. This is because MassiveKB cannot handle too many processes downloading simultaneously. Running more than 10 processes increases the likelihood of a task failing with an exit code 58. Running the pipeline with these settings on the calcua tier 2 supercomputer for the first 100 tasks took 6 hours.  
  
Another sidenote is that quite some tasks fail with exit code 186, this is because some tasks have no mzTab file included.  


## Extra functionality
### Simple run
The mztab file itself contains charge and m/z values, so if only these two are needed, downloading all the mzML/mzXML files is unnecessary. To optimize performance, the workflows _run_tasks_simple_ and _download_and_run_tasks_simple_ were implemented, significantly speeding up the process. These workflows can collect the dataset in approximately three hours when running 60 processes concurrently.

 Two examples:
```bash
nextflow run main.nf -c config_files/local.config -entry download_and_run_tasks_simple -with-docker  
```
```bash  
 nextflow run main.nf -c config_files/local.config -entry run_tasks_simple --input input_files/first_100.tsv -with-docker  
 ```  

### Concatenate
This workflows take a directory as input and will concatenate all the files in it into a dataset.parquet file.
 For the regular workflow run:
```bash
nextflow run main.nf -entry concatenate -c config_files/local.config --max_processes 1 --input results/psms --memory 5.GB -with-docker
```
For the simple workflow run:
```bash
nextflow run main.nf -entry concatenate_simple -c config_files/local.config --max_processes 1 --input results/psms --memory 5.GB -with-docker
```





  
## Pipeline Structure  
This section provides an overview of the structure  
    
``` 
massivekb_pipeline/
├── dockerfile                  # Defines the Docker image (pulled automatically from DockerHub)  
├── main.nf                     # Main Nextflow file containing all workflows  
├── modules.nf                  # Defines all Nextflow processes as modules  
├── README.md                   # Project documentation  
├── requirements.txt           # Dependencies for Docker image
├── bin/                        # Python scripts  
│   ├── get_psm.py              # Extracts PSMs from mzTab files
│   ├── get_tasks.py            # Extracts unique tasks from metadata
│   ├── parse.py              # Parses mzML/mzXML files and generates final PSMs 
│   ├── to_parquet.py           writes a tsv file to a .parquet dataframe
├── Config_files/               # Nextflow configuration files
│   ├── local.config            # Config for local execution  
│   ├── slurm.config            # Config for SLURM execution
├── Input_files/                # example task input files 
│   ├── all_tasks.tsv           # All unique tasks in the metadata  
│   ├── first_100.tsv           # First 100 unique tasks  
│   ├── one_task.tsv            # Single task example  
├── Slurm_example_scripts/      # Directory containing example slurm task scripts  
```   
## Acknowledgement  
I would like to express my sincere gratitude to the following individuals for their invaluable guidance and support throughout this project.  
  
First and foremost, I would like to thank **Wout Bittrieux** and **Ceder Dens** for their assistance in explaining the structure of the dataset and helping me understand the various challenges and problems that arose during the process.  
  
I am also grateful to **Wim Cuypers** for his guidance on using Nextflow, as well as for providing helpful examples and resources that were crucial in my learning of the tool.  
  
Finally, I would like to thank **Haliil Dazdos** for his support with explaining the best way to download the mzTab files which is an important part in this pipeline.  
  
Their contributions were crucial to the success of this project, and I truly appreciate their expertise and willingness to share their insights with me.  
  
## Contact    
    
For questions , please contact Wannes Lamberts at [[wannes.lamberts@student.uantwerpen.be](mailto:your-email@example.com)].