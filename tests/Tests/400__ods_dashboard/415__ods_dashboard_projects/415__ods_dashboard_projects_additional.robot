*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/OCP.resource
Resource           ../../../Resources/ODS.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource           ../../../Resources/Page/ODH/JupyterHub/GPU.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project 2
${PRJ_TITLE_GPU}=   ODS-CI DS Project GPU
${PRJ_RESOURCE_NAME}=   ods-ci-ds-project-test-additional
${PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a test project for validating DS Project feature
${TOLERATIONS}=    workbench-tolerations
${DEFAULT_TOLERATIONS}=    NotebooksOnly   
${WORKBENCH_TITLE}=   ODS-CI Workbench Tolerations
${WORKBENCH_DESCRIPTION}=   ${WORKBENCH_TITLE} is a test workbench to check tolerations are applied
${WORKBENCH_TITLE_GPU}=   ODS-CI Workbench GPU
${WORKBENCH_DESCRIPTION_GPU}=   ${WORKBENCH_TITLE_GPU} is a test workbench using GPU
${NB_IMAGE}=        Minimal Python
${NB_IMAGE_GPU}=        PyTorch
${PV_NAME}=         ods-ci-tolerations
${PV_NAME_GPU}=         ods-ci-gpu
${PV_DESCRIPTION}=         it is a PV created to test DS Projects feature
${PV_SIZE}=         1


*** Test Cases ***
Verify Notebook Tolerations Are Applied To Workbenches When Set Up
    [Documentation]    Verifies workbenches get the custom tolerations set by
    ...                admins in "Cluster Settings" page
    [Tags]    Tier1    Sanity
    ...       ODS-1969
    Open Dashboard Cluster Settings
    Set Pod Toleration Via UI    ${TOLERATIONS}
    Save Changes In Cluster Settings
    Launch Data Science Project Main Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Sleep   20s    reason=Wait enough time for letting Dashboard to fetch the latest toleration settings
    Create Workbench    workbench_title=${WORKBENCH_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Verify Server Workbench Has The Expected Toleration    workbench_title=${WORKBENCH_TITLE}
    ...    toleration=${TOLERATIONS}    project_title=${PRJ_TITLE}
    [Teardown]    Restore Tolerations Settings And Clean Project

Verify User Can Add GPUs To Workbench
    [Documentation]    Verifies user can add GPUs to an already started workbench
    [Tags]    Tier1    Sanity
    ...       ODS-2013    Resources-GPU
    Launch Data Science Project Main Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE_GPU}  workbench_description=${EMPTY}
    ...    prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE_GPU}   deployment_size=Small
    ...    storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME_GPU}
    ...    pv_description=${EMPTY}  pv_size=${PV_SIZE}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    Edit GPU Number    workbench_title=${WORKBENCH_TITLE_GPU}    gpus=1
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Restarting    workbench_title=${WORKBENCH_TITLE_GPU}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    ...    timeout=60s
    Verify Workbench Pod Has Limits And Requests For GPU    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    project_title=${PRJ_TITLE}    exp_gpu_value=1
    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Open New Notebook In Jupyterlab Menu
    Verify Pytorch Can See GPU
    [Teardown]    Clean Project    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    pvc_title=${PV_NAME_GPU}    project_title=${PRJ_TITLE}

Verify User Can Remove GPUs From Workbench
    [Documentation]    Verifies user can remove GPUs from an already started workbench
    [Tags]    Tier1    Sanity
    ...       ODS-2014    Resources-GPU
    Launch Data Science Project Main Page
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE_GPU}  workbench_description=${EMPTY}
    ...    prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE_GPU}   deployment_size=Small
    ...    storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME_GPU}
    ...    pv_description=${EMPTY}  pv_size=${PV_SIZE}    gpus=1
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    Sleep    10s     reason=There is some delay in updating the GPU availability in Dashboard
    Run Keyword And Continue On Failure    GPU Dropdown Should Be Disabled    workbench_title=${WORKBENCH_TITLE_GPU}
    Click Button    ${GENERIC_CANCEL_BTN_XP}
    Stop Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Run Keyword And Continue On Failure    Wait Until Workbench Is Stopped     workbench_title=${WORKBENCH_TITLE_GPU}
    Wait Until Keyword Succeeds    10 times    5s
    ...    Edit GPU Number    workbench_title=${WORKBENCH_TITLE_GPU}    gpus=0
    Wait Until Project Is Open    project_title=${PRJ_TITLE}
    Start Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Verify Workbench Pod Does Not Have Limits And Requests For GPU    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    project_title=${PRJ_TITLE}  
    Run Keyword And Continue On Failure    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE_GPU}
    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE_GPU}
    Open New Notebook In Jupyterlab Menu
    Run Keyword And Expect Error    'Using cpu device' does not match 'Using cuda device'    Verify Pytorch Can See GPU
    [Teardown]    Clean Project    workbench_title=${WORKBENCH_TITLE_GPU}
    ...    pvc_title=${PV_NAME_GPU}    project_title=${PRJ_TITLE}


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
    Launch Data Science Project Main Page
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${PRJ_RESOURCE_NAME}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Verify Server Workbench Has The Expected Toleration
    [Documentation]    Verifies notebook pod created as workbench
    ...                contains toleration
    [Arguments]    ${workbench_title}    ${project_title}    ${toleration}
    ${expected}=    Set Variable    ${toleration}:NoSchedule op=Exists
    ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
    ${_}  ${workbench_cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}
    ...    namespace=${namespace}
    ${received}=    Get Pod Tolerations    ${workbench_cr_name}-0
    ...    ns=${namespace}
    List Should Contain Value  ${received}  ${expected}
    ...    msg=Unexpected Pod Toleration

Restore Tolerations Settings And Clean Project
    [Documentation]    Reset the notebook tolerations after testing
    Open Dashboard Cluster Settings
    Wait for RHODS Dashboard to Load    expected_page=Cluster Settings
    ...    wait_for_cards=${FALSE}
    Set Pod Toleration Via UI    ${DEFAULT_TOLERATIONS}
    Disable Pod Toleration Via UI
    Save Changes In Cluster Settings
    Clean Project    workbench_title=${WORKBENCH_TITLE}
    ...    pvc_title=${PV_NAME}    project_title=${PRJ_TITLE}

Clean Project
    [Documentation]    Deletes resources from a test project to free up
    ...                resources or re-use titles
    [Arguments]    ${workbench_title}    ${pvc_title}
    ...            ${project_title}
    Delete Workbench From CLI    workbench_title=${workbench_title}
    ...    project_title=${project_title}
    Delete PVC From CLI    pvc_title=${pvc_title}    project_title=${project_title}
    Sleep    10s    reason=There is some delay in updating the GPU availability in Dashboard

Verify Workbench Pod Has Limits And Requests For GPU
    [Documentation]    Checks if the notebook/workbench pod has all the limits/requests
    ...                set, including the ones for GPUs
    [Arguments]    ${workbench_title}    ${project_title}    ${exp_gpu_value}
    ${ns_name}    ${cr_name}    ${pod_info}=    Get Workbench Pod    workbench_title=${workbench_title}
    ...    project_title=${project_title}
    Check Limits And Requests For Every Workbench Pod Container
    ...    containers_info=${pod_info[0]['spec']['containers']}
    ...    wb_cr_name=${cr_name}    gpu_present=${TRUE}    exp_gpu_value=${exp_gpu_value}

Verify Workbench Pod Does Not Have Limits And Requests For GPU
    [Documentation]    Checks if the notebook/workbench pod has all the limits/requests
    ...                set, including the ones for GPUs
    [Arguments]    ${workbench_title}    ${project_title}
    ${ns_name}    ${cr_name}    ${pod_info}=    Get Workbench Pod    workbench_title=${workbench_title}
    ...    project_title=${project_title}
    Check Limits And Requests For Every Workbench Pod Container
    ...    containers_info=${pod_info[0]['spec']['containers']}
    ...    wb_cr_name=${cr_name}    gpu_present=${FALSE}

Check Limits And Requests For Every Workbench Pod Container
    [Documentation]    Loops through each container inside a workbench
    ...                to check if limits and requests are set
    [Arguments]    ${containers_info}    ${wb_cr_name}    ${gpu_present}=${TRUE}    ${exp_gpu_value}=1
    FOR    ${container_info}    IN    @{containers_info}
        ${container_name}=    Set Variable    ${container_info['name']}
        IF    "${container_name}" == "${wb_cr_name}"
            Verify CPU And Memory Requests And Limits Are Defined For Pod Container    ${container_info}
            ...    nvidia_gpu=${gpu_present}
            ${requests}=    Set Variable     ${container_info['resources']['requests']}
            ${limits}=    Set Variable     ${container_info['resources']['limits']}
            IF    ${gpu_present} == ${TRUE}
                Run Keyword And Continue On Failure
                ...    Should Be Equal     ${requests['nvidia.com/gpu']}    ${exp_gpu_value}
                Run Keyword And Continue On Failure
                ...    Should Be Equal     ${limits['nvidia.com/gpu']}    ${exp_gpu_value}
            ELSE
                Run Keyword And Continue On Failure
                ...    Dictionary Should Not Contain Key    ${requests}    nvidia.com/gpu
                Run Keyword And Continue On Failure
                ...    Dictionary Should Not Contain Key    ${limits}    nvidia.com/gpu
            END
        ELSE
            Verify CPU And Memory Requests And Limits Are Defined For Pod Container    ${container_info}
            ...    nvidia_gpu=${FALSE}
        END
    END
