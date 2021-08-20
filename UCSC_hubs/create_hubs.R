library("recount3")
library("here")
library("sessioninfo")

## Function for creating hubs
create_hub <-
    function(x,
        output_dir = ".",
        hub_name = "recount3",
        email = "someone@somewhere",
        show_max = 5,
        hub_short_label = "recount3 coverage",
        hub_long_label = "recount3 summaries and queries for large-scaleRNA-seq expression and splicing",
        hub_description_url = "https://rna.recount.bio/index.html",
        recount3_url = getOption("recount3_url", "http://duffel.rail.bio/recount3")) {
        stopifnot(is(x, "data.frame"))
        stopifnot(all(
            c(
                "external_id",
                "project",
                "organism",
                "file_source",
                "project_home"
            ) %in% colnames(x)
        ))
        stopifnot(length(unique(x$organism)) == 1)

        if (grepl(" ", hub_name)) {
            stop(
                "hub_name should be a single word starting with a letter as stated at http://genome.ucsc.edu/goldenPath/help/hgTrackHubHelp.html.",
                call. = FALSE
            )
        }
        if (nchar(hub_short_label) > 17) {
            warning(
                "The recommended maximum character length for the short label is 17 at http://genome.ucsc.edu/goldenPath/help/hgTrackHubHelp.html.",
                call. = FALSE
            )
        }
        if (nchar(hub_long_label) > 80) {
            warning(
                "The recommended maximum character length for the long label is 80 at http://genome.ucsc.edu/goldenPath/help/hgTrackHubHelp.html.",
                call. = FALSE
            )
        }

        dir.create(output_dir, recursive = TRUE)

        content_hub <-
            paste0(
                "hub ",
                hub_name,
                "\nshortLabel ",
                hub_short_label,
                "\nlongLabel ",
                hub_long_label,
                "\ngenomesFile genomes.txt\nemail ",
                email,
                "\ndescriptionUrl ",
                hub_description_url,
                "\n"
            )
        writeLines(content_hub, file.path(output_dir, "hub.txt"))

        org <- ifelse(unique(x$organism) == "human", "hg38", "mm10")
        dir.create(file.path(output_dir, org))
        content_genomes <-
            paste0("genome ", org, "\ntrackDb ", org, "/trackDb.txt\n")
        writeLines(content_genomes, file.path(output_dir, "genomes.txt"))

        by_proj <- split(x, paste0(x$project, "-", x$organism))

        x_bw <- do.call(rbind, lapply(by_proj, function(proj) {
            cbind(
                proj,
                bigWig = locate_url(
                    project = proj$project[1],
                    project_home = proj$project_home[1],
                    type = "bw",
                    organism = proj$organism[1],
                    recount3_url = recount3_url,
                    sample = x$external_id
                )
            )
        }))

        content_trackDb <-
            paste0(
                "track ",
                x_bw$external_id,
                "\nbigDataUrl ",
                x_bw$bigWig,
                "\nshortLabel ",
                x_bw$external_id,
                "\nlongLabel recount3 coverage bigWig for external id ",
                x_bw$external_id,
                " project ",
                x_bw$project,
                " file source ",
                x_bw$file_source,
                "\ntype bigWig\nvisibility ",
                ifelse(seq_len(nrow(x_bw)) <= show_max, "show", "hide"),
                "\nautoScale on\n"
            )
        writeLines(content_trackDb,
            file.path(output_dir, org, "trackDb.txt"))

    }


## Obtain all available samples
samples <- rbind(recount3::available_samples("human"),
    recount3::available_samples("mouse"))


## Test with DRP001299
x <- subset(samples, project == "DRP001299")
create_hub(
    x,
    hub_name = "DRP001299",
    email = "lcolladotor@gmail.com",
    output_dir = here("UCSC_hubs", "mouse", "DRP001299")
)

## test with
## https://genome.ucsc.edu/cgi-bin/hgTracks?db=mm10&lastVirtModeType=default&lastVirtModeExtraState=&virtModeType=default&virtMode=0&nonVirtPosition=&position=chr1&hubUrl=https://raw.githubusercontent.com/LieberInstitute/recount3-docs/master/UCSC_hubs/mouse/DRP001299/hub.txt

## can also work for one sample at a time like at
## http://genome.ucsc.edu/cgi-bin/hgTracks?db=mm10&position=chr1&hgct_customText=track%20type=bigWig%20name=DRR014696%20description=%22a%20bigWig%20track%22%20visibility=full%20bigDataUrl=http://duffel.rail.bio/recount3/mouse/data_sources/sra/base_sums/99/DRP001299/96/sra.base_sums.DRP001299_DRR014696.ALL.bw

## Reproducibility information
print('Reproducibility information:')
Sys.time()
proc.time()
options(width = 120)
session_info()
