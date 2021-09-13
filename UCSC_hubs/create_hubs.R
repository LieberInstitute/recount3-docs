library("recount3")
library("here")
library("sessioninfo")

## Obtain all available samples
samples <- rbind(recount3::available_samples("human"),
    recount3::available_samples("mouse"))


## Test with DRP001299
# x <- subset(samples, project == "DRP001299")
# create_hub(
#     x,
#     hub_name = "DRP001299",
#     email = "lcolladotor@gmail.com",
#     output_dir = here("UCSC_hubs", "mouse", "sra_DRP001299")
# )

## test with
## https://genome.ucsc.edu/cgi-bin/hgTracks?db=mm10&lastVirtModeType=default&lastVirtModeExtraState=&virtModeType=default&virtMode=0&nonVirtPosition=&position=chr1&hubUrl=https://raw.githubusercontent.com/LieberInstitute/recount3-docs/master/UCSC_hubs/mouse/sra_DRP001299/hub.txt

## can also work for one sample at a time like at
## http://genome.ucsc.edu/cgi-bin/hgTracks?db=mm10&position=chr1&hgct_customText=track%20type=bigWig%20name=DRR014696%20description=%22a%20bigWig%20track%22%20visibility=full%20bigDataUrl=http://duffel.rail.bio/recount3/mouse/data_sources/sra/base_sums/99/DRP001299/96/sra.base_sums.DRP001299_DRR014696.ALL.bw

## Create for all projects
samples_by_proj <- split(samples, paste0(samples$project, "-", samples$organism))
xx <- lapply(samples_by_proj, function(x) {
    create_hub(x, hub_name = x$project[1], email = "lcolladotor@gmail.com", output_dir = here("UCSC_hubs", x$organism[1], paste0(x$file_source[1], "_", x$project[1])))
})

## test a large one (GTEx brain) with
## https://genome.ucsc.edu/cgi-bin/hgTracks?db=hg38&lastVirtModeType=default&lastVirtModeExtraState=&virtModeType=default&virtMode=0&nonVirtPosition=&position=chr1&hubUrl=https://raw.githubusercontent.com/LieberInstitute/recount3-docs/master/UCSC_hubs/human/gtex_BRAIN/hub.txt

## Reproducibility information
print('Reproducibility information:')
Sys.time()
proc.time()
options(width = 120)
session_info()
