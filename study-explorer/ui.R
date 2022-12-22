library('shiny')
library("recount3")

options("recount3_url" = "https://sciserver.org/public-data/recount3/data")

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
    tags$h2("Access data"),
    helpText("Click on a row in the above table to select a project of interest."),
    selectInput("annotation", "Select annotation", choices = recount3::annotation_options(), selected = recount3::annotation_options()[1]),
    uiOutput("raw_file_links"),
    tags$hr()
)
