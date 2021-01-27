library('shiny')
library("recount3")

bootstrapPage(
    tags$hr(),
    tags$h2("recount3 study explorer"),
    helpText("Under project_home you can subset for GTEx, TCGA or SRA. Note that GTEx v8 and TCGA are split by tissue."),
    DT::dataTableOutput('metadata', width = "95%"),
    tags$hr(),
    downloadButton(
        'downloadData',
        'Download list of projects matching search results'
    ),
    tags$hr(),
    tags$h2("Raw files"),
    helpText("Click on a row in the above table to select a project of interest."),
    selectInput("annotation", "Select annotation", choices = recount3::annotation_options(), selected = recount3::annotation_options()[1]),
    uiOutput("raw_file_links"),
    helpText("Use recount3::locate_url() for obtaining the bigWig URLs for each sample."),
    tags$hr()
)
