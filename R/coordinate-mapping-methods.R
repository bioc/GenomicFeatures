### =========================================================================
### mapToTranscripts() and pmapToTranscripts() methods
### -------------------------------------------------------------------------
###

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Generics
###

setGeneric("mapToTranscripts", signature=c("x", "transcripts"),
    function(x, transcripts, ...)
        standardGeneric("mapToTranscripts")
)

setGeneric("pmapToTranscripts", signature=c("x", "transcripts"),
    function(x, transcripts, ...)
        standardGeneric("pmapToTranscripts")
)

setGeneric("mapFromTranscripts", signature=c("x", "transcripts"),
    function(x, transcripts, ...)
        standardGeneric("mapFromTranscripts")
)

setGeneric("pmapFromTranscripts", signature=c("x", "transcripts"),
    function(x, transcripts, ...)
        standardGeneric("pmapFromTranscripts")
)

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Helpers
###

### 'x' is a GRangesList
### This function returns a GRangesList with sorted elements. It
### differs from sort() in that "-" strand elements are returned
### highest value to lowest.
.orderElementsByTranscription <- function(x) {
    part <- PartitioningByWidth(x)
    original <- sequence(elementNROWS(part))
    ## order by position
    gr <- unlist(x, use.names = FALSE)
    idx <- order(togroup(part), start(gr))
    gr <- gr[idx]
    ## handle zero-width ranges
    pstart <- start(part)[width(part) != 0L]
    pend <- end(part)[width(part) != 0L]

    neg <- strand(gr)[pstart] == "-"
    ord <- sequence(width(part), from=ifelse(neg, pend, pstart),
                                 by=ifelse(neg, -1L, 1L))
    res <- relist(gr[ord], x)
    res@unlistData$unordered <- original[idx[ord]]
    res
}

### 'x' is an IntegerList or NumericList
### This function returns a numeric vector of cumulative sums within list
### elements.
.listCumsumShifted <- function(x) {
    cs <- unlist(cumsum(x), use.names=FALSE)
    shifted <- c(0L, head(cs, -1))
    shifted[start(PartitioningByWidth(elementNROWS(x)))] <- 0L
    shifted
}

.pmap_recycle <- function(x, len) {
    if (length(x) != len && length(x) != 1L) {
        stop(paste0("recycling is supported when length(x) == 1 or ",
                    "length(transcripts) == 1; ",
                    "otherwise the lengths must match"))
    }
    rep(x, length.out=len)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### mapToTranscripts()
###

### No need for IntegerRanges methods when mapping to transcripts. Plain
### ranges only make sense in the transcript space.

.mapToTranscripts <- function(x, transcripts, hits,
                              ignore.strand, intronJunctions=FALSE)
{
    if (is(x, "GPos"))
        x <- as(x, "GRanges")
    flat <- unlist(transcripts, use.names=FALSE)
    seqlengths <- sum(width(transcripts))[unique(names(transcripts))]
    nonHits <- !seq_along(x) %in% queryHits(hits)
    xnonHits <- x[nonHits]

    ## 'x' spans introns
    if (any(nonHits) && any(lengths(transcripts) > 1L)) {
        within <- countOverlaps(xnonHits, range(transcripts), type="within", 
                                ignore.strand=ignore.strand) 
        index <- nonHits
        index[which(nonHits)[within == 0]] <- FALSE 
        if (any(index)) {
            span <- findOverlaps(x[index], flat, 
                                 minoverlap=1L, select="all",
                                 ignore.strand=ignore.strand)
            tx <- togroup(PartitioningByWidth(transcripts))[subjectHits(span)]
            txgroups1 <- split(tx, queryHits(span))
            keep <- lengths(txgroups1) > 1
            if (any(keep)) {
                ii <- as.integer(names(txgroups1))[keep]
                xmapback <- seq_along(index)[index][ii]
                txgroups2 <- split(subjectHits(span), queryHits(span))
                rangemin <- min(List(txgroups2[keep]))
                query <- c(queryHits(hits), xmapback)
                subject <- c(subjectHits(hits), unlist(rangemin))
                hits <- Hits(query, subject, length(x), length(flat),
                             sort.by.query=TRUE)
            }
        }
    }
    ## 'x' falls within an intron
    if (intronJunctions) {
        if (any(nonHits)) {
            follows <- follow(xnonHits, flat, ignore.strand=ignore.strand)
            precedes <- precede(xnonHits, flat, ignore.strand=ignore.strand)
            introns <- logical(length(nonHits))
            introns[nonHits] <-  !is.na(follows & precedes)
            if (any(introns)) {
                ## modify 'x'
                subjectIdx <- na.omit(follows[follows & precedes])
                stopifnot(length(subjectIdx) == sum(introns))
                nstrand <- as.logical(strand(flat[subjectIdx]) == "-")
                ends <- end(flat[subjectIdx])
                ends[nstrand] <- start(flat[subjectIdx[nstrand]]) - 1L
                ranges(x[introns]) <- IRanges(end=ends, width=0L)
                ## modify 'hits'
                query <- c(queryHits(hits), seq_along(x)[introns])
                subject <- c(subjectHits(hits), subjectIdx)
                intronic <- c(logical(length(queryHits(hits))),
                                !logical(sum(introns)))
                hits <- Hits(query, subject, length(x), length(flat),
                             intronic=intronic, sort.by.query=TRUE)
            }
        } else mcols(hits)$intronic <- logical(length(hits))
    }
    ## process all hits
    if (length(hits)) {
        xHits <- queryHits(hits)
        txHits <- subjectHits(hits)
        xrange <- ranges(x)[xHits]
        bounds <- ranges(flat)[txHits]

        ## Adjust location wrt to individual list elements
        neg <- as.vector(strand(flat)[txHits] == "-")
        negstart <- end(bounds)[neg] - end(xrange)[neg] + 1L
        xrange[neg] <- IRanges(negstart, width=width(xrange)[neg])
        xrange[!neg] <- shift(xrange[!neg], - start(bounds)[!neg] + 1L)
        transcriptsHits=togroup(PartitioningByWidth(transcripts))[txHits]

        ## Adjust location and width wrt concatenated list elements
        if (length(flat) > length(transcripts)) {
            shifted <- .listCumsumShifted(width(transcripts))
            xrange <- shift(xrange, shifted[txHits])
            intronwidth <- psetdiff(x[xHits], transcripts[transcriptsHits])
            width(xrange) <- width(xrange) - sum(width(intronwidth))
        }

        ## seqnames come from 'transcripts'
        df <- DataFrame(xHits=xHits, transcriptsHits=transcriptsHits)
        if (intronJunctions)
            df$intronic <- mcols(hits)$intronic
        GRanges(factor(names(transcripts)[transcriptsHits],
                       unique(names(transcripts))),
                xrange, strand(flat)[txHits], df,
                seqlengths=seqlengths)
    } else {
        ans <- GRanges(seqlengths=seqlengths)
        df <- DataFrame(xHits=integer(), transcriptsHits=integer())
        if (intronJunctions)
            df$intronic <- logical()
        mcols(ans) <- df
        ans
    }
}

setMethod("mapToTranscripts", c("GenomicRanges", "GenomicRanges"),
    function(x, transcripts, ignore.strand=FALSE)
    {
        grl <- as(transcripts, "CompressedGRangesList")
        mapToTranscripts(x, grl, ignore.strand)
    }
)

setMethod("mapToTranscripts", c("GenomicRanges", "GRangesList"),
    function(x, transcripts, ignore.strand=FALSE, intronJunctions=FALSE)
    {
        if (!length(x) && !length(transcripts))
            return(GRanges(xHits=integer(), transcriptsHits=integer()))
        if (is.null(names(transcripts)))
            stop ("'transcripts' must have names")
        if (ignore.strand) {
            strand(transcripts) <- "*"
        } else if (any(elementNROWS(runValue(strand(transcripts))) > 1)) {
                stop(paste0("when ignore.strand=TRUE all inner list elements",
                            "of 'transcripts' must be the same strand"))
        }

        ## order within list elements by strand
        transcripts <- .orderElementsByTranscription(transcripts)

        ## findOverlaps determines pairs
        hits <- findOverlaps(x, unlist(transcripts, use.names=FALSE),
                             minoverlap=1L, type="within",
                             ignore.strand=ignore.strand)
        map <- .mapToTranscripts(x, transcripts, hits,
                                 ignore.strand, intronJunctions)
        if (is(x, "GPos"))
            map <- as(map, "GPos")  # would loose the names if 'map' had any
        map
    }
)

setMethod("mapToTranscripts", c("ANY", "TxDb"),
    function(x, transcripts, ignore.strand=FALSE,
             extractor.fun=GenomicFeatures::transcripts, ...)
    {
        if (!is.function(extractor.fun))
            stop("'extractor.fun' must be a function")
        group1 <- c("transcripts", "exons", "cds", "genes",
                    "promoters", "terminators",
                    "exonicParts", "microRNAs", "tRNAs")
        group2 <- c("transcriptsBy", "exonsBy", "cdsBy", "intronsByTranscript",
                    "fiveUTRsByTranscript", "threeUTRsByTranscript")

        fname <- extractor.fun@generic
        if (fname %in% group1) {
            transcripts <- extractor.fun(transcripts, ...)
            if (is.null(names(transcripts)))
                names(transcripts) <- mcols(transcripts)[,1]
        } else if (fname %in% group2) {
            transcripts <- extractor.fun(transcripts, ...)
        } else {
            stop("invalid 'extractor.fun'")
        }
        mapToTranscripts(x, transcripts, ignore.strand=ignore.strand)
    }
)

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### pmapToTranscripts()
###

setMethod("pmapToTranscripts", c("GenomicRanges", "GenomicRanges"),
    function(x, transcripts, ignore.strand=FALSE)
    {
        grl <- as(transcripts, "CompressedGRangesList")
        pmapToTranscripts(x, grl, ignore.strand)
    }
)

setMethod("pmapToTranscripts", c("GRangesList", "GRangesList"),
          function(x, transcripts, ignore.strand=FALSE)
          {
              gr <- unlist(x, use.names=FALSE)
              ans <- pmapToTranscripts(gr,
                  transcripts[togroup(PartitioningByWidth(x))],
                  ignore.strand)
              reduce(relist(ans, x))
          })

setMethod("pmapToTranscripts", c("GenomicRanges", "GRangesList"),
    function(x, transcripts, ignore.strand=FALSE)
    {
        if (!length(x))
            return(GRanges())
        if (is.null(names(transcripts)))
            names(transcripts) <- as.character(seq_along(transcripts))
        if (ignore.strand) {
            strand(transcripts) <- "*"
        } else if (!all(elementNROWS(runLength(strand(transcripts))) == 1)) {
            stop(paste0("when ignore.strand=TRUE all inner list elements ",
                        "of 'transcripts' must be the same strand"))
        }

        ## order within list elements by strand
        transcripts <- .orderElementsByTranscription(transcripts)

        ## recycling
        maxlen <- max(length(x), length(transcripts))
        x <- .pmap_recycle(x, maxlen)
        transcripts <- .pmap_recycle(transcripts, maxlen)

        ## map i-th elements
        hits <- findOverlaps(x, unlist(transcripts, use.names=FALSE),
                             minoverlap=1L, type="within",
                             ignore.strand=ignore.strand)
        ith <- queryHits(hits) ==
               togroup(PartitioningByWidth(transcripts))[subjectHits(hits)]
        map <- .mapToTranscripts(x, transcripts, hits[ith], ignore.strand)

        ## non-hits
        if (length(x) != length(map)) {
            s <- rep(0L, length(x))
            e <- rep(-1L, length(x))
            seqname <- names(transcripts)
            strands <- Rle("*", length(x))
            xHits <- mcols(map)$xHits
            e[xHits] <- end(map)
            s[xHits] <- start(map)
            strands[xHits] <- strand(map)
            map <- GRanges(seqname, IRanges(s, e, names=names(x)), strands,
                           seqinfo=seqinfo(map))
        } else {
            mcols(map) <- NULL
        }
        if (is(x, "GPos"))
            map <- as(map, "GPos")  # would loose the names if 'map' had any
        map
    }
)

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### mapFromTranscripts()
###

## use seqnames of 'x' and names of 'transcripts' for mapping

.mapFromTranscripts <- function(x, transcripts, hits, ignore.strand)
{
    if (length(hits)) {
        xHits <- queryHits(hits)
        txHits <- subjectHits(hits)

        ## Check strand in this helper because 'hits' was not constructed
        ## with findOverlaps() or any other strand-aware method.
        if (is(transcripts, "GRangesList"))
            txstrand <- unlist(runValue(strand(transcripts)), use.names=FALSE)
        else
            txstrand <- as.factor(strand(transcripts))
        strand <- tmpstrand <- as.character(txstrand)[txHits]
        if (ignore.strand || all(tmpstrand == "*")) {
            strand(x) <- strand(transcripts) <- "*"
            mismatch <- logical(length(xHits))
            tmpstrand <- rep("+", length(xHits))
            strand <- rep("*", length(xHits))
        } else {
            mismatch <- (as.numeric(strand(x)[xHits]) +
                        as.numeric(txstrand[txHits])) == 3L
        }

        ## mapping
        xStart <- as.list(start(x)[xHits])
        xEnd <- as.list(end(x)[xHits])
        txStart <- as.list(start(transcripts)[txHits])
        txEnd <- as.list(end(transcripts)[txHits])
        s <- unlist(transcriptLocs2refLocs(xStart, txStart, txEnd, tmpstrand,
                                           FALSE, FALSE), use.names=FALSE)
        e <- unlist(transcriptLocs2refLocs(xEnd, txStart, txEnd, tmpstrand,
                                           FALSE, FALSE), use.names=FALSE)

        ## reverse start and end for negative strand
        if (!ignore.strand && any(nstrand <- strand == "-")) {
            start <- s
            end <- e
            start[nstrand] <- e[nstrand]
            end[nstrand] <- s[nstrand]
            s <- start
            e <- end
        }

        sn <- unlist(seqnames(transcripts), use.names=FALSE)
        if (is(transcripts, "GRangesList"))
            sn <- sn[start(PartitioningByEnd(transcripts))]
        sn <- sn[txHits]

        ## non-hits qualified as 'UNMAPPED'
        if (any(skip <- is.na(s) | is.na(e) | mismatch)) {
            s[skip] <- 0L
            e[skip] <- -1L
            levels(sn) <- c(levels(sn), "UNMAPPED")
            sn[skip] <- Rle("UNMAPPED")
        }
        if (!is.null(xnames <- names(x)))
            xnames <- xnames[xHits]
        GRanges(sn, IRanges(s, e, names=xnames),
                strand=strand, DataFrame(xHits, transcriptsHits=txHits))
    } else {
        ans <- GRanges()
        mcols(ans) <- DataFrame(xHits=integer(), transcriptsHits=integer())
        ans
    }
}

setMethod("mapFromTranscripts", c("GenomicRanges", "GenomicRanges"),
    function(x, transcripts, ignore.strand=FALSE)
    {
        grl <- relist(transcripts, PartitioningByEnd(seq_along(transcripts),
                      names=names(transcripts)))
        map <- mapFromTranscripts(x, grl, ignore.strand)

        ## remove zero-width ranges
        if (any(zeroWidth <- width(map) == 0L))
            map <- map[!zeroWidth]

        map
    }
)

setMethod("mapFromTranscripts", c("GenomicRanges", "GRangesList"),
    function(x, transcripts, ignore.strand=FALSE)
    {
        if (!length(x) || !length(transcripts))
            return(GRanges(xHits=integer(), transcriptsHits=integer()))

        if (ignore.strand) {
            strand(transcripts) <- "*"
        } else if (!all(elementNROWS(runLength(strand(transcripts))) == 1)) {
            stop(paste0("when ignore.strand=TRUE all inner list ",
                        "elements of 'transcripts' must be the same strand"))
        }

        ## order within list elements by strand
        transcripts <- .orderElementsByTranscription(transcripts)

        xNames <- as.character(seqnames(x))
        txNames <- names(transcripts)
        if (is.null(txNames))
            stop ("'transcripts' must have names")

        ## name matching determines pairs
        match0 <- match(txNames, txNames)
        match1 <- match(xNames, txNames)
        group0 <- splitAsList(seq_along(txNames), match0)
        group1 <- group0[match(na.omit(match1), names(group0))]
        xHits <- rep(which(!is.na(match1)), elementNROWS(group1))
        txHits <- unlist(group1, use.names=FALSE)
        if (!length(xHits <- na.omit(xHits)))
            stop ("none of 'names(x)' are in 'names(transcripts)'")

        ## construct Hits
        hits <- Hits(xHits, txHits, length(x), length(transcripts),
                     sort.by.query=TRUE)
        map <- .mapFromTranscripts(x, transcripts, hits, ignore.strand)
        ## remove zero-width ranges
        if (any(zeroWidth <- width(map) == 0L))
            map <- map[!zeroWidth]

        map
    }
)

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### pmapFromTranscripts()
###

.pmapFromTranscripts_ranges <- function(x, transcripts)
{
    if (!length(x) || !length(transcripts))
        if (is(transcripts, "GRangesList"))
            return(GRangesList())
        else return(GRanges())

    ## recycling
    maxlen <- max(length(x), length(transcripts))
    x <- .pmap_recycle(x, maxlen)
    transcripts <- .pmap_recycle(transcripts, maxlen)

    ## strand from 'transcripts'
    if (is(transcripts, "GRangesList"))
        txstrand <- unlist(runValue(strand(transcripts)), use.names=FALSE)
    else
        txstrand <- as.character(strand(transcripts))
    strand <- tmpstrand <- as.character(txstrand)

    ## mapping
    xStart <- as.list(start(x))
    xEnd <- as.list(end(x))
    txStart <- as.list(start(transcripts))
    txEnd <- as.list(end(transcripts))
    s <- unlist(transcriptLocs2refLocs(xStart, txStart, txEnd, tmpstrand,
                                       FALSE, FALSE), use.names=FALSE)
    e <- unlist(transcriptLocs2refLocs(xEnd, txStart, txEnd, tmpstrand,
                                       FALSE, FALSE), use.names=FALSE)
    ## reverse start and end for negative strand
    if (any(nstrand <- tmpstrand == "-")) {
        start <- s
        end <- e
        start[nstrand] <- e[nstrand]
        end[nstrand] <- s[nstrand]
        s <- start
        e <- end
    }

    sn <- unlist(seqnames(transcripts), use.names=FALSE)
    if (is(transcripts, "GRangesList"))
        sn <- sn[start(PartitioningByEnd(transcripts))]

    ## non-hits
    if (any(skip <- is.na(s) | is.na(e))) {
        s[skip] <- 0L
        e[skip] <- -1L
        levels(sn) <- c(levels(sn), "UNMAPPED")
        sn[skip] <- Rle("UNMAPPED")
    }

    GRanges(sn, IRanges(s, e), strand=tmpstrand)
}

setMethod("pmapFromTranscripts", c("IntegerRanges", "GenomicRanges"),
          function(x, transcripts)
              .pmapFromTranscripts_ranges(x, transcripts)
)

## return GRangesList to preserve exon structure
setMethod("pmapFromTranscripts", c("IntegerRanges", "GRangesList"),
    function(x, transcripts)
    {
        if (!length(x) || !length(transcripts))
            return(GRangesList())
        if (!all(elementNROWS(runLength(strand(transcripts))) == 1)) {
            stop(paste0("when ignore.strand=TRUE all inner list ",
                        "elements of 'transcripts' must have the same strand"))
        }

        ## recycling
        maxlen <- max(length(x), length(transcripts))
        x <- .pmap_recycle(x, maxlen)
        transcripts <- .pmap_recycle(transcripts, maxlen)

        map <- .pmapFromTranscripts_ranges(x,
            .orderElementsByTranscription(transcripts))
        pintersect(transcripts, map)
    }
)

setMethod("pmapFromTranscripts", c("GenomicRanges", "GenomicRanges"),
    function(x, transcripts, ignore.strand=FALSE)
    {
        if (!length(x) || !length(transcripts))
            return(GRanges())

        ## recycling
        maxlen <- max(length(x), length(transcripts))
        x <- .pmap_recycle(x, maxlen)
        transcripts <- .pmap_recycle(transcripts, maxlen)

        ## map i-th elements
        hits <- Hits(seq_along(x), seq_along(x), length(x), length(x),
                     sort.by.query=TRUE)
        .mapFromTranscripts(x, transcripts, hits, ignore.strand)
    }
)

## return GRangesList to preserve exon structure
setMethod("pmapFromTranscripts", c("GenomicRanges", "GRangesList"),
    function(x, transcripts, ignore.strand=FALSE)
    {
        if (!length(x) || !length(transcripts))
            return(GRangesList())

        if (ignore.strand) {
            strand(transcripts) <- "*"
        } else if (!all(elementNROWS(runLength(strand(transcripts))) == 1)) {
            stop(paste0("when ignore.strand=TRUE all inner list ",
                        "elements of 'transcripts' must have the same strand"))
        }

        ## recycling
        maxlen <- max(length(x), length(transcripts))
        x <- .pmap_recycle(x, maxlen)
        transcripts <- .pmap_recycle(transcripts, maxlen)

        ## map i-th elements
        hits <- Hits(seq_along(x), seq_along(x), length(x), length(x),
                     sort.by.query=TRUE)
        map <- .mapFromTranscripts(x,
                                   .orderElementsByTranscription(transcripts),
                                   hits, ignore.strand)
        pintersect(transcripts, map)
    }
)
