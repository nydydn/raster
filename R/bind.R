# Author: Robert J. Hijmans
# Date : November 2011
# Version 1.0
# Licence GPL v3



.uniqueNames <- function(x, sep='.') {
	y <- as.matrix(table(x))
	y <- y[y[,1] > 1, ,drop=F]
	if (nrow(y) > 0) {
		y <- rownames(y)
		for (i in 1:length(y)) {
			j <- which(x==y[i])
			x[j] <- paste(x[j], sep, 1:length(j), sep='')
		}
	}
	x
}


if (!isGeneric("bind")) {
	setGeneric("bind", function(x, y, ...)
		standardGeneric("bind"))
}	


setMethod('bind', signature(x='data.frame', y='missing'), 
	function(x, y, ..., variables=NULL) {
		if (!is.null(variables)) {
			variables <- as.character(stats::na.omit(variables))
			if (length(variables) > 1) {
				x <- x[, which(colnames(x) %in% variables), drop=FALSE]
			} 
		}
		return(x)
	}
)

setMethod('bind', signature(x='data.frame', y='data.frame'), 
function(x, y, ..., variables=NULL) {
	x <- .frbind(x, y)
	if (!is.null(variables)) {
		variables <- as.character(stats::na.omit(variables))
		if (length(variables) > 1) {
			x <- x[, which(colnames(x) %in% variables), drop=FALSE]
		} else {
			variables <- NULL
		}
	}
	dots <- list(...)
	if (length(dots) > 1) {
		for (i in 1:length(dots)) {
			d <- dots[[i]]
			if (!inherits(d, 'data.frame')) {
				next
			}
			if (!is.null(variables)) {
				d <- d[, which(colnames(d) %in% variables), drop=FALSE]
			}
			if (nrow(d) > 0) {
				x <- .frbind(x, d)
			}
		}
	}
	x
}
)


setMethod('bind', signature(x='SpatialPolygons', y='SpatialPolygons'), 
function(x, y, ..., keepnames=FALSE) {

		x <- list(x, y, ...)

		#p <- sapply(x, proj4string)
		#if (!isTRUE(all(p==p[1]))) { }
		haswarned <- FALSE
		projx <- proj4string(x[[1]])
		for (i in 2:length(x)) {
			if (is.na(proj4string(x[[i]]))) {
				x[[i]]@proj4string <- x[[1]]@proj4string			
			} else if (! identical(projx, proj4string(x[[i]])) ) {
				if (!haswarned) {
					warning('non identical CRS')
					haswarned <- TRUE
				}
				x[[i]]@proj4string <- x[[1]]@proj4string
			}
		}	
				
		rwn <- lapply(x, row.names)
		i <- sapply(rwn, length) > 0
		if (!all(i)) {
			if (!any(i)) {
				return(x[[1]])
			}
			x <- x[i]
			if (length(x) == 1) {
				return( x[[1]] )
			}
		}

		ln <- sapply(rwn, length)
		rnu <- .uniqueNames(unlist(rwn, use.names = FALSE))
		end <- cumsum(ln)
		start <- c(0, end[-length(end)]) + 1
		for (i in 1:length(x)) {
			if (keepnames) {
				if (! all(rnu[start[i]:end[i]] == rwn[[i]]) ) {
					row.names(x[[i]]) <- rnu[start[i]:end[i]]
				}
			} else {
				row.names(x[[i]]) <- as.character(start[i]:end[i])
			}	
		}

		cls <- sapply(x, class)
		if (all(cls == 'SpatialPolygons')) {
			return( do.call( rbind, x))
		}

		if (all(cls == 'SpatialPolygonsDataFrame')) {
			dat <- lapply( x, function(x) { methods::slot(x, 'data') } )
			dat <- do.call(.frbind, dat)
			x <- sapply(x, function(y) methods::as(y, 'SpatialPolygons'))
			x <- do.call( rbind, x)
			rownames(dat) <- row.names(x)
			return( SpatialPolygonsDataFrame(x, dat) )
		}

		
		dat <- NULL
#		dataFound <- FALSE
		for (i in 1:length(x)) {
			if (methods::.hasSlot(x[[i]], 'data')) {
#				dataFound <- TRUE
				if (is.null(dat)) {
					dat <- x[[i]]@data
				} else {
					dat <- .frbind(dat, x[[i]]@data)
				}
			} else {
				if ( is.null(dat)) {
					dat <- data.frame()
					dat[1:length(x[[i]]@polygons),] <- NA
					rownames(dat) <- row.names(x[[i]])
				} else {
					dat[(nrow(dat)+1):(nrow(dat) + length(x[[i]])),] <- NA
				}	
			}
		}
#		if (! dataFound ) { return( do.call(rbind, x) ) }
		x <- sapply(x, function(x) methods::as(x, 'SpatialPolygons'))
		x <- do.call(rbind, x)
		SpatialPolygonsDataFrame(x, dat)
}
)




setMethod('bind', signature(x='SpatialLines', y='SpatialLines'), 
	function(x, y, ..., keepnames=FALSE) {

		x <- list(x, y, ...)

		haswarned <- FALSE
		projx <- proj4string(x[[1]])
		for (i in 2:length(x)) {
			if (is.na(proj4string(x[[i]]))) {
				x[[i]]@proj4string <- x[[1]]@proj4string			
			} else if (! identical(projx, proj4string(x[[i]])) ) {
				if (!haswarned) {
					warning('non identical CRS')
					haswarned <- TRUE
				}
				x[[i]]@proj4string <- x[[1]]@proj4string
			}
		}	
		
		
		rwn <- lapply(x, row.names)
		i <- sapply(rwn, length) > 0
		if (!all(i)) {
			if (!any(i)) {
				return(x[[1]])
			}
			x <- x[i]
			if (length(x) == 1) {
				return( x[[1]] )
			}
		}

		ln <- sapply(rwn, length)
		rnu <- .uniqueNames(unlist(rwn, use.names = FALSE))
		end <- cumsum(ln)
		start <- c(0, end[-length(end)]) + 1
		for (i in 1:length(x)) {
			if (keepnames) {
				if (! all(rnu[start[i]:end[i]] == rwn[[i]]) ) {
					row.names(x[[i]]) <- rnu[start[i]:end[i]]
				}
			} else {
				row.names(x[[i]]) <- as.character(start[i]:end[i])
			}	
		}

		cls <- sapply(x, class)
		if (all(cls == 'SpatialLines')) {
			return( do.call( rbind, x))
		}

		if (all(cls == 'SpatialLinesDataFrame')) {
			dat <- lapply( x, function(x) { methods::slot(x, 'data') } )
			dat <- do.call(.frbind, dat)
			x <- sapply(x, function(y) methods::as(y, 'SpatialLines'))
			x <- do.call( rbind, x)
			rownames(dat) <- row.names(x)
			return( SpatialLinesDataFrame(x, dat) )
		}

		
		dat <- NULL
#		dataFound <- FALSE
		for (i in 1:length(x)) {
			if (methods::.hasSlot(x[[i]], 'data')) {
#				dataFound <- TRUE
				if (is.null(dat)) {
					dat <- x[[i]]@data
				} else {
					dat <- .frbind(dat, x[[i]]@data)
				}
			} else {
				if ( is.null(dat)) {
					dat <- data.frame()
					dat[1:length(x[[i]]@lines),] <- NA
					rownames(dat) <- row.names(x[[i]])
				} else {
					dat[(nrow(dat)+1):(nrow(dat)+nrow(x[[i]]@coords)),] <- NA
				}	
			}
		}
#		if (! dataFound ) { return( do.call(rbind, x) ) }
		x <- sapply(x, function(x) methods::as(x, 'SpatialLines'))
		x <- do.call(rbind, x)
		SpatialLinesDataFrame(x, dat)
}
)




setMethod('bind', signature(x='SpatialPoints', y='SpatialPoints'),
	function(x, y, ..., keepnames=FALSE) {

		x <- list(x, y, ...)

		rwn <- lapply(x, row.names)
		i <- sapply(rwn, length) > 0
		if (!all(i)) {
			if (!any(i)) {
				return(x[[1]])
			}
			x <- x[i]
			if (length(x) == 1) {
				return( x[[1]] )
			}
		}

		ln <- sapply(rwn, length)
		rnu <- .uniqueNames(unlist(rwn, use.names = FALSE))
		end <- cumsum(ln)
		start <- c(0, end[-length(end)]) + 1
		for (i in 1:length(x)) {
			if (keepnames) {
				if (! all(rnu[start[i]:end[i]] == rwn[[i]]) ) {
					row.names(x[[i]]) <- rnu[start[i]:end[i]]
				}
			} else {
				row.names(x[[i]]) <- as.character(start[i]:end[i])
			}	
		}

		cls <- sapply(x, class)
		if (all(cls == 'SpatialPoints')) {
			return( do.call( rbind, x))
		}

		if (all(cls == 'SpatialPointsDataFrame')) {
			dat <- lapply( x, function(x) { methods::slot(x, 'data') } )
			dat <- do.call(.frbind, dat)
			x <- sapply(x, function(y) methods::as(y, 'SpatialPoints'))
			x <- do.call( rbind, x)
			rownames(dat) <- row.names(x)
			return( SpatialPointsDataFrame(x, dat) )
		}
		
		dat <- NULL
		for (i in 1:length(x)) {
			if (methods::.hasSlot(x[[i]], 'data')) {
				if (is.null(dat)) {
					dat <- x[[i]]@data
				} else {
					dat <- .frbind(dat, x[[i]]@data)
				}
			} else {
				if ( is.null(dat)) {
					dat <- data.frame()
					dat[1:nrow(x[[i]]@coords),] <- NA
					rownames(dat) <- row.names(x[[i]])
				} else {
					dat[(nrow(dat)+1):(nrow(dat)+nrow(x[[i]]@coords)),] <- NA
				}	
			}
		}
#		if (! dataFound ) { return( do.call(rbind, x) ) }
		x <- sapply(x, function(x) methods::as(x, 'SpatialPoints'))
		x <- do.call(rbind, x)
		SpatialPoinsDataFrame(x, dat)
}
)


