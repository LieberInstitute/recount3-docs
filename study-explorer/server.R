library("shiny")
library("DT")
library("recount3")
library("purrr")

load("projects_meta.Rdata")

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
            current <- projects_meta[input$metadata_rows_all, ]
            write.csv(current, file, row.names = FALSE)
        }
    )

    observeEvent(input$metadata_cell_clicked, {
        info <- input$metadata_cell_clicked
        if (is.null(info$value))
            return()

        current <- projects_meta[info$row, ]
        current$organism <- as.character(current$organism)

        ## Get the available annotation options for the chosen organism
        ann_options <- recount3::annotation_options(current[["organism"]])

        curr_ann <- input$annotation
        if(!curr_ann %in% ann_options) {
            ## Update annotation options if necessary
            updateSelectInput(inputId = "annotation",
                choices = ann_options,
                selected = ann_options[1])
        }
    })

    output$raw_file_links <- renderUI({

        info <- input$metadata_cell_clicked
        if (is.null(info$value))
            return()

        current <- projects_meta[info$row, ]
        current$project <- as.character(current$project)
        current$project_home <- as.character(current$project_home)
        current$organism <- as.character(current$organism)

        ## Get the available annotation options for the chosen organism
        ann_options <- recount3::annotation_options(current[["organism"]])

        curr_ann <- input$annotation
        if(!curr_ann %in% ann_options) {
            ## Avoid issues with changing organisms across multiple clicks
            curr_ann <- ann_options[1]
        }

        project_urls <- unlist(purrr::map(c("gene", "exon", "jxn", "metadata"), ~ recount3::locate_url(
            project = current[["project"]],
            project_home = current[["project_home"]],
            type = .x,
            organism = current[["organism"]],
            annotation = curr_ann
        )))

        ann_urls <- purrr::map_chr(c("gene", "exon"), ~ recount3::locate_url_ann(
            type = .x,
            organism = current[["organism"]],
            annotation = curr_ann
        ))

        url_text <-
            purrr::map2_chr(
                c(project_urls, ann_urls),
                c(
                    paste(current[["project"]],
                        c(
                            paste(c(
                                "gene counts for",
                                "exon counts for"),
                                curr_ann
                            ),
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
                    paste(c(
                        "Gene annotation for",
                        "Exon annotation for"
                    ), curr_ann)

                ),
                ~
                    paste0('<li><b><a href="', .x, '">', .y, "</a></b></li>")
            )

        tags$ul(HTML(url_text))
    })



})
