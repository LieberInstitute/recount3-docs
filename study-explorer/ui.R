library('shiny')
library("recount3")

bootstrapPage(
    tags$hr(),
    tags$h2("recount3 study explorer"),
    helpText(
        "Under project_home you can subset for GTEx, TCGA or SRA. Note that GTEx v8 and TCGA are split by tissue."
    ),
    DT::dataTableOutput('metadata', width = "95%"),
    tags$hr(),
    downloadButton(
        'downloadData',
        'Download list of projects matching search results'
    ),
    tags$hr(),
    tags$h2("Access data"),
    helpText("Click on a row in the above table to select a project of interest."),
    # dput(recount3::annotation_options())
    selectInput(
        "annotation",
        "Select annotation",
        choices = c(
            "gencode_v26",
            "gencode_v29",
            "fantom6_cat",
            "refseq",
            "ercc",
            "sirv"
        ),
        selected = "gencode_v26"
    ),
    uiOutput("raw_file_links"),
    tags$hr()
)
