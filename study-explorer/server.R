library("shiny")
library("DT")
library("recount3")
library("purrr")

load("projects_meta.Rdata")

## Use https instead of http for duffel to resolve basically the same issue
## as in https://github.com/leekgroup/recount-website/issues/25
options("recount3_url" = "https://duffel.rail.bio/recount3")

projects_meta <-
    projects_meta[, c("organism",
        "project_home",
        "project",
        "n_samples",
        "study_title",
        "study_abstract")]

projects_meta$organism <- factor(projects_meta$organism)
projects_meta$project_home <- factor(projects_meta$project_home)
projects_meta$project <- factor(projects_meta$project)

shinyServer(function(input, output, session) {
    output$metadata <- DT::renderDataTable(
        projects_meta,
        style = 'bootstrap',
        rownames = FALSE,
        filter = 'top',
        options = list(
            pageLength = 3,
            lengthMenu = c(1, 3, 5, 10, 25, 50, 100, nrow(projects_meta)),
            order = list(list(3, 'desc'))
        )
    )

    output$downloadData <- downloadHandler(
        filename = function() {
            paste0('recount3_selection_', Sys.time(),
                '.csv')
        },
        content = function(file) {
            current <- projects_meta[input$metadata_rows_all,]
            write.csv(current, file, row.names = FALSE)
        }
    )

    get_current <- reactive({
        info <- input$metadata_cell_clicked
        if (is.null(info$value))
            return()

        current <- projects_meta[info$row,]
        current$project <- as.character(current$project)
        current$project_home <- as.character(current$project_home)
        current$organism <- as.character(current$organism)

        return(current)
    })

    observeEvent(input$metadata_cell_clicked, {
        info <- input$metadata_cell_clicked
        if (is.null(info$value))
            return()

        current <- get_current()

        ## Get the available annotation options for the chosen organism
        ann_options <-
            recount3::annotation_options(current[["organism"]])

        curr_ann <- input$annotation
        if (!curr_ann %in% ann_options) {
            ## Update annotation options if necessary
            updateSelectInput(
                inputId = "annotation",
                choices = ann_options,
                selected = ann_options[1]
            )
        }
    })

    output$raw_file_links <- renderUI({
        info <- input$metadata_cell_clicked
        if (is.null(info$value))
            return()

        current <- get_current()

        ## Get the available annotation options for the chosen organism
        ann_options <-
            recount3::annotation_options(current[["organism"]])

        curr_ann <- input$annotation
        if (!curr_ann %in% ann_options) {
            ## Avoid issues with changing organisms across multiple clicks
            curr_ann <- ann_options[1]
        }

        project_urls <-
            unlist(purrr::map(
                c("gene", "exon", "jxn", "metadata"),
                ~ recount3::locate_url(
                    project = current[["project"]],
                    project_home = current[["project_home"]],
                    type = .x,
                    organism = current[["organism"]],
                    annotation = curr_ann
                )
            ))

        ann_urls <-
            purrr::map_chr(
                c("gene", "exon"),
                ~ recount3::locate_url_ann(
                    type = .x,
                    organism = current[["organism"]],
                    annotation = curr_ann
                )
            )

        ucsc_url <-
            paste0(
                "https://genome.ucsc.edu/cgi-bin/hgTracks?db=",
                ifelse(current[["organism"]] == "human", "hg38", "mm10"),
                "&lastVirtModeType=default&lastVirtModeExtraState=&virtModeType=default&virtMode=0&nonVirtPosition=&position=chr1&hubUrl=https://raw.githubusercontent.com/LieberInstitute/recount3-docs/master/UCSC_hubs/",
                current[["organism"]],
                "/",
                basename(current[["project_home"]]),
                "_",
                current[["project"]],
                "/hub.txt"
            )

        url_text <-
            purrr::map2_chr(
                c(project_urls, ann_urls),
                c(paste(
                    current[["project"]],
                    c(
                        paste(c(
                            "gene counts for",
                            "exon counts for"
                        ),
                            curr_ann),
                        "junctions (MM)",
                        "junctions (RR)",
                        "junctions (ID)",
                        "metadata (proj_meta)",
                        "metadata (recount_project)",
                        "metadata (recount_qc)",
                        "metadata (recount_seq_qc)",
                        "metadata (pred)"
                    )
                ),
                    paste(
                        c("Gene annotation for",
                            "Exon annotation for"),
                        curr_ann
                    )),
                ~
                    paste0('<li><b><a href="', .x, '">', .y, "</a></b></li>")
            )

        ## Create R code for downloading the study with R
        output$recount3_code <- renderText({
            ## Construct R code for creating the RSE object with R
            paste0(
                'recount3::create_rse_manual(\n    project = "',
                current[["project"]],
                '",\n    project_home = "',
                current[["project_home"]],
                '",\n    organism = "',
                current[["organism"]],
                '",\n    annotation = "',
                curr_ann,
                '",\n    type = "gene"\n)'
            )

        })

        ## Download BigWig file URLs
        output$downloadBigWigList <- downloadHandler(
            filename = function() {
                gsub(":", "-", gsub(
                    " ",
                    "_",
                    paste0(
                        "recount3_study-explorer_BigWig_list_",
                        current[["organism"]],
                        "_",
                        basename(current[["project_home"]]),
                        "_",
                        current[["project"]],
                        ".csv"
                    )
                ))
            },
            content = function(file) {
                ## Locate all metadata files
                meta_urls <- locate_url(
                    project = current[["project"]],
                    project_home = current[["project_home"]],
                    type = "metadata",
                    organism = current[["organism"]]
                )

                ## Just read in the most basic one
                meta_proj <-
                    read_metadata(metadata_files = file_retrieve(meta_urls[grep("recount_project", names(meta_urls))]))

                ## Locate BigWig URLs
                meta_proj$BigWigURL <- locate_url(
                    project = current[["project"]],
                    project_home = current[["project_home"]],
                    type = "bw",
                    organism = current[["organism"]],
                    sample = meta_proj$external_id
                )

                ## Finish with a basic recount3 metadata file structure:
                ## rail_id, external_id, study
                ## plus the BigWigURL
                write.csv(meta_proj[, c("rail_id", "external_id", "study", "BigWigURL")], file, row.names = FALSE)
            }
        )

        tagList(
            tags$h3("R code for this study (recommended option)"),
            helpText(
                "You can use the following R code to obtain the data for this study:"
            ),
            verbatimTextOutput("recount3_code"),
            helpText(
                "Change the 'type' argument from 'gene' to 'exon' or 'jxn' to download the exon or exon-exon junction data instead of the gene data."
            ),
            helpText(
                HTML(
                    "Check the <a href='http://rna.recount.bio/docs/quick-access.html'>recount3 quick access documentation</a> for more information on installing the recount3 R/Bioconductor package."
                )
            ),
            tags$hr(),
            tags$h3("UCSC Genome Browser for this study"),
            helpText(
                "You can view the base-pair coverage BigWig files on the UCSC Genome Browser by opening the link below in a new tab."
            ),
            tags$ul(HTML(
                paste0(
                    '<li><b><a href="',
                    ucsc_url,
                    '">BigWig UCSC track hub</a></b></li>'
                )
            )),
            tags$hr(),
            tags$h3("Raw files for this study"),
            helpText(
                "If you prefer to access the raw files, you can download them manually through the following links. These raw files are used by recount3::create_rse() and recount3::create_rse_manual() so most users will not interact with these files directly."
            ),
            tags$ul(HTML(url_text)),
            downloadButton(
                "downloadBigWigList",
                "Base-pair coverage BigWig file URLs"
            ),
            helpText(
                HTML(
                    "Check the <a href='http://rna.recount.bio/docs/quick-access.html'>recount3 quick access documentation</a> for more information on the raw files provided by recount3."
                )
            )
        )
    })

})
