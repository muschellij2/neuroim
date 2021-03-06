#' @import iterators

#' @include AllClass.R
{}
#' @include AllGeneric.R
{}


#' Create an instance of class \code{\linkS4class{ROIVolume}}
#' 
#' @param vspace an instance of class \code{BrainSpace}
#' @param coords matrix of voxel coordinates
#' @param data the data values, numeric vector or matrix
#' @return an instance of class \code{ROIVolume}
#' @rdname ROIVolume
#' @export
ROIVolume <- function(vspace, coords, data=rep(nrow(coords),1)) {
  new("ROIVolume", space=vspace, coords=coords, data=data)
}


#' Create an instance of class \code{\linkS4class{ROISurface}}
#' 
#' @param geometry the parent geometry: an instance of class \code{SurfaceGeometry}
#' @param indices the parent surface indices
#' @param data the data values, numeric \code{vector} or \code{matrix}
#' @return an instance of class \code{ROISurface}
#' @rdname ROISurface
#' @export
ROISurface <- function(geometry, indices, data) {
  vert <- vertices(geometry, indices)
  new("ROISurface", geometry=geometry, data=data, coords=vert, indices=indices)
}
  

.makeSquareGrid <- function(bvol, centroid, surround, fixdim=3) {
  vspacing <- spacing(bvol)
  vdim <- dim(bvol)
  centroid <- as.integer(centroid)
  
  dimnums <- seq(1,3)[-fixdim]
  
  coords <- lapply(centroid, function(x) { round(seq(x-surround, x+surround)) })
  coords <- lapply(dimnums, function(i) {
    x <- coords[[i]]
    x[x > 0 & x <= vdim[i]]
  })
  
  if (all(sapply(coords, length) == 0)) {
    stop(paste("invalid cube for centroid", centroid, " with surround", surround, ": volume is zero"))
  }
  
  if (fixdim == 3) {
    grid <- as.matrix(expand.grid(x=coords[[1]],y=coords[[2]],z=centroid[3]))
  } else if (fixdim == 2) {
    grid <- as.matrix(expand.grid(x=coords[[1]],y=centroid[2],z=coords[[2]]))
  } else if (fixdim == 1) {
    grid <- as.matrix(expand.grid(x=centroid[1],y=coords[[1]],z=coords[[2]]))
  }
  
  grid
  
}

.makeCubicGrid <- function(bvol, centroid, surround) {
  vspacing <- spacing(bvol)
  vdim <- dim(bvol)
  centroid <- as.integer(centroid)
  
  coords <- lapply(centroid, function(x) { round(seq(x-surround, x+surround)) })
  coords <- lapply(1:3, function(i) {
    x <- coords[[i]]
    x[x > 0 & x <= vdim[i]]
  })
 
  if (all(sapply(coords, length) == 0)) {
    stop(paste("invalid cube for centroid", centroid, " with surround", surround, ": volume is zero"))
  }
  
  grid <- as.matrix(expand.grid(x=coords[[1]],y=coords[[2]],z=coords[[3]]))
}



#' Create a square region of interest where the z-dimension is fixed at one voxel coordinate.
#' @param bvol an \code{BrainVolume} or \code{BrainSpace} instance.
#' @param centroid the center of the cube in \emph{voxel} coordinates.
#' @param surround the number of voxels on either side of the central voxel.
#' @param fill optional value(s) to assign to data slot.
#' @param nonzero keep only nonzero elements from \code{bvol}. If \code{bvol} is A \code{BrainSpace} then this argument is ignored.
#' @param fixdim the fixed dimension is the third, or z, dimension.
#' @return an instance of class \code{ROIVolume}.
#' @examples
#'  sp1 <- BrainSpace(c(10,10,10), c(1,1,1))
#'  square <- RegionSquare(sp1, c(5,5,5), 1)
#'  vox <- coords(square)
#'  ## a 3 X 3 X 1 grid
#'  nrow(vox) == 9
#' @export
RegionSquare <- function(bvol, centroid, surround, fill=NULL, nonzero=FALSE, fixdim=3) {
  if (is.matrix(centroid)) {
    centroid <- drop(centroid)
  }
  
  if (length(centroid) != 3) {
    stop("RegionSquare: centroid must have length of 3 (x,y,z coordinates)")
  }
  
  if (surround < 0) {
    stop("'surround' argument cannot be negative")
  }
  
  if (is(bvol, "BrainSpace") && is.null(fill)) {
    fill = 1
  }
  
  grid <- .makeSquareGrid(bvol,centroid,surround,fixdim=fixdim)
  
  vals <- if (!is.null(fill)) {
    rep(fill, nrow(grid))
  } else {
    ## coercion to numeric shouldn't be necessary here.
    as.numeric(bvol[grid])
  }   
  
  keep <- if (nonzero) {
    which(vals != 0)    
  } else {
    seq_along(vals)
  }
  
  ### add central voxel
  new("ROIVolume", space = space(bvol), data = vals[keep], coords = grid[keep, ])
  
}

  
#' Create A Cuboid Region of Interest
#' @param bvol an \code{BrainVolume} or \code{BrainSpace} instance
#' @param centroid the center of the cube in \emph{voxel} coordinates
#' @param surround the number of voxels on either side of the central voxel. A \code{vector} of length 3.
#' @param fill optional value(s) to assign to data slot. 
#' @param nonzero keep only nonzero elements from \code{bvol}. If \code{bvol} is A \code{BrainSpace} then this argument is ignored.
#' @return an instance of class \code{ROIVolume}
#' @rdname RegionCube
#' @examples
#'  sp1 <- BrainSpace(c(10,10,10), c(1,1,1))
#'  cube <- RegionCube(sp1, c(5,5,5), 3)
#'  vox <- coords(cube)
#'  cube2 <- RegionCube(sp1, c(5,5,5), 3, fill=5)
#'  
#'  
#' @export
RegionCube <- function(bvol, centroid, surround, fill=NULL, nonzero=FALSE) {
  if (is.matrix(centroid)) {
    centroid <- drop(centroid)
  }
  
  if (length(centroid) != 3) {
    stop("RegionCube: centroid must have length of 3 (x,y,z coordinates)")
  }
  
  if (surround < 0) {
    stop("'surround' argument cannot be negative")
  }
  
  if (is(bvol, "BrainSpace") && is.null(fill)) {
    fill = 1
  }
  
  grid <- .makeCubicGrid(bvol,centroid,surround)
  
  vals <- if (!is.null(fill)) {
    rep(fill, nrow(grid))
  } else {
    as.numeric(bvol[grid])
  }   
  
  keep <- if (nonzero) {
    which(vals != 0)    
  } else {
    seq_along(vals)
  }
  
  ### add central voxel
  new("ROIVolume", space = space(bvol), data = vals[keep], coords = grid[keep, ])
  
}


.makeSphericalGrid <- function(bvol, centroid, radius) {
  vspacing <- spacing(bvol)
  vdim <- dim(bvol)
  centroid <- as.integer(centroid)
  mcentroid <- ((centroid-1) * vspacing + vspacing/2)
  cubedim <- ceiling(radius/vspacing)
  
  nsamples <- max(cubedim) * 2 + 1
  vmat <- apply(cbind(cubedim, centroid), 1, function(cdim) {
    round(seq(cdim[2] - cdim[1], cdim[2] + cdim[1], length.out=nsamples))
  })
  
  vlist <- lapply(1:NCOL(vmat), function(i) {
    v <- vmat[,i]
    unique(v[v >= 1 & v <= vdim[i]])
  })
  
  
  if (all(sapply(vlist, length) == 0)) {
    stop(paste("invalid sphere for centroid", paste(centroid, collapse=" "), " with radius",
               radius))
  }

 
  grid <- as.matrix(expand.grid(x = vlist[[1]], y = vlist[[2]], z = vlist[[3]]))
  
  dvals <- apply(grid, 1, function(gvals) {
    coord <- (gvals-1) * vspacing + vspacing/2
    sqrt(sum((coord - mcentroid)^2))
  })
  
  grid[which(dvals <= radius),]
  
}


#' @title Create a Region on Surface 
#' @description Creates a Region on a Surface from a radius and surface
#' 
#' @param surf a \code{SurfaceGeometry} or \code{BrainSurface} or \code{BrainSurfaceVector}
#' @param index the index of the central surface node
#' @param radius the size in mm of the geodesic radius
#' @param max_order maximum number of edges to traverse. 
#'   default is computed based on averaged edge length.
#' @importFrom assertthat assert_that
#' @importFrom igraph E V ego distances induced_subgraph V neighborhood
#' @rdname SurfaceDisk
#' @export
SurfaceDisk <- function(surf, index, radius, max_order=NULL) {
  assertthat::assert_that(length(index) == 1)
  
  edgeWeights=igraph::E(surf@graph)$dist

  if (is.null(max_order)) {
    avg_weight <- mean(edgeWeights)
    max_order <- ceiling(radius/avg_weight) + 1
  }

  cand <- as.vector(igraph::ego(surf@graph, order= max_order, nodes=index)[[1]])
  D <- igraph::distances(surf@graph, index, cand, weights=edgeWeights, algorithm="dijkstra")
  keep <- which(D < radius)
  
  if (inherits(surf, "BrainSurface") || inherits(surf, "BrainSurfaceVector")) {
    ROISurface(surf@geometry, indices=cand[keep], data=series(surf, keep))
  } else {
    ROISurface(surf, indices=cand[keep], rep(1, length(keep)))
  }
  
}

#' @title Create a Spherical Region of Interest
#' 
#' @description Creates a Spherical ROI based on a Centroid.
#' @param bvol an \code{BrainVolume} or \code{BrainSpace} instance
#' @param centroid the center of the sphere in voxel space
#' @param radius the radius in real units (e.g. millimeters) of the spherical ROI
#' @param fill optional value(s) to store as data
#' @param nonzero if \code{TRUE}, keep only nonzero elements from \code{bvol}
#' @return an instance of class \code{ROIVolume}
#' @examples
#'  sp1 <- BrainSpace(c(10,10,10), c(1,2,3))
#'  cube <- RegionSphere(sp1, c(5,5,5), 3.5)
#'  vox <- coords(cube)
#'  cds <- coords(cube, real=TRUE)
#'  ## fill in ROI with value of 6
#'  cube1 <- RegionSphere(sp1, c(5,5,5), 3.5, fill=6)
#'  all(cube1@data == 6)
#' @export
RegionSphere <- function (bvol, centroid, radius, fill=NULL, nonzero=FALSE) {
  if (is.matrix(centroid)) {
    assertthat::assert_that(ncol(centroid == 3) & nrow(centroid) == 1)
    centroid <- drop(centroid)
  }
  
  assertthat::assert_that(length(centroid) == 3)
  
  if (is.null(fill) && is(bvol, "BrainSpace")) {
    fill = 1
  }
  
  bspace <- space(bvol)
  vspacing <- spacing(bvol)
  vdim <- dim(bvol)
  centroid <- as.integer(centroid)
  grid <- .makeSphericalGrid(bvol, centroid, radius)
   
  vals <- if (!is.null(fill)) {
    rep(fill, nrow(grid))
  } else {    
    as.numeric(bvol[grid])
  }   
  
  if (nonzero) {
    keep <- vals != 0 
    new("ROIVolume", space = bspace, data = vals[keep], coords = grid[keep, ,drop=FALSE])
  } else {
    new("ROIVolume", space = bspace, data = vals, coords = grid)
  }
  
}

.resample <- function(x, ...) x[sample.int(length(x), ...)]

#' Create an spherical random searchlight iterator
#' 
#' @param mask an volumetric image mask of type \code{\linkS4class{BrainVolume}} containing valid searchlight voxel set.
#' @param radius in mm of spherical searchlight
#' @export
RandomSearchlight <- function(mask, radius) {
  done <- array(FALSE, dim(mask))
  mask.idx <- which(mask != 0)
  grid <- indexToGrid(mask, mask.idx)
  

  prog <- function() { sum(done)/length(mask.idx) }
  
  nextEl <- function() {
    if (!all(done[mask.idx])) {
      center <- .resample(which(!done[mask.idx]), 1)
      search <- RegionSphere(mask, grid[center,], radius, nonzero=TRUE) 
      vox <- coords(search)
      vox <- vox[!done[vox],,drop=FALSE]
      #done[center] <<- TRUE
      done[vox] <<- TRUE
      attr(vox, "center") <- grid[center,]
      attr(vox, "center.index") <- mask.idx[center]
      vox
      
    } else {
      stop('StopIteration')
    }
  }
  obj <- list(nextElem=nextEl, progress=prog)
  class(obj) <- c("RandomSearchlight", 'abstractiter', 'iter')
  obj
}

#' Create a spherical searchlight iterator that samples regions from within a mask.
#' 
#' searchlight centers are sampled without replacement, but the same surround voxel can belong to multiple searchlight samples.
#' @param mask an image volume containing valid central voxels for roving searchlight
#' @param radius in mm of spherical searchlight
#' @param iter the total number of searchlights to sample (default is 100).
#' @export
BootstrapSearchlight <- function(mask, radius, iter=100) {
  mask.idx <- which(mask != 0)
  grid <- indexToGrid(mask, mask.idx)
  index <- 0
  
  sample.idx <- sample(1:nrow(grid))
  
  prog <- function() { index/length(mask.idx) }
  
  nextEl <- function() {
    if (index <= iter & length(sample.idx) > 0) { 
      index <<- index + 1
      
      cenidx <- sample.idx[1]
      sample.idx <<- sample.idx[-1]
      
      search <- RegionSphere(mask, grid[cenidx,], radius, nonzero=TRUE) 
      vox <- search@coords
      attr(vox, "center") <- grid[cenidx,]
      attr(vox, "center.index") <- mask.idx[cenidx]
      vox
    } else {
      stop('StopIteration')
    }
  }
  
  obj <- list(nextElem=nextEl, progress=prog)
  class(obj) <- c("BootstrapSearchlight", 'abstractiter', 'iter')
  obj
  
}

#' Create a Random Searchlight iterator for surface mesh using geodesic distance to define regions.
#' 
#' @param surfgeom a surface mesh: instance of class \code{\linkS4class{SurfaceGeometry}}
#' @param radius radius of the searchlight as a geodesic distance in mm
#' @param nodeset the subset of surface node indices to use
#' @importFrom igraph neighborhood induced_subgraph
#' @export
#' @details 
#'   On every call to \code{nextElem} a set of surface nodes are returned. 
#'   These nodes index into the vertices of the \code{igraph} instance.
#' 
#' @examples
#' file <- system.file("extdata", "std.lh.smoothwm.asc", package = "neuroim")
#' geom <- loadSurface(file)
#' searchlight <- RandomSurfaceSearchlight(geom, 12)
#' nodes <- searchlight$nextElem()
#' length(nodes) > 1
#' 
RandomSurfaceSearchlight <- function(surfgeom, radius=8, nodeset=NULL) {
  subgraph <- FALSE
  if (is.null(nodeset)) {
    ## use all surface nodes
    nodeset <- nodes(surfgeom)
    g <- surfgeom@graph
  } else {
    ## use supplied subset
    g <- igraph::induced_subgraph(graph(surfgeom), nodeset)
    subgraph <- TRUE
  }
  
  
  bg <- neighborGraph(g, radius=radius)
  
  index <- 0
  
  nds <- as.vector(igraph::V(bg))
  done <- logical(length(nds))
  
  prog <- function() { sum(done)/length(done) }
  
  nextEl <- function() {
    if (!all(done)) {
      ## sample from remaining nodes
      center <- .resample(which(!done), 1)
      indices <- as.vector(igraph::neighborhood(bg, 1, nds[center])[[1]])
      indices <- indices[!done[indices]]
      done[indices] <<- TRUE
      
      if (subgraph) {
        ## index into to absolute graph nodes
        vout <- nodeset[indices]
        attr(vout, "center") <- nodeset[center]
        attr(vout, "center.index") <- nodeset[center]
        vout
      } else {
        attr(indices, "center") <- center
        attr(indices, "center.index") <- center
        indices
      }
        
    } else {
      stop('StopIteration')
    }
  }
  
  obj <- list(nextElem=nextEl, progress=prog)
  class(obj) <- c("RandomSurfaceSearchlight", 'abstractiter', 'iter')
  obj
  
}


#' Create a Searchlight iterator for surface mesh using geodesic distance to define regions.
#' 
#' @param surfgeom a surface mesh: instance of class \code{SurfaceGeometry}
#' @param radius radius of the searchlight as a geodesic distance in mm
#' @param nodeset the subset of surface nodes to use
#' @importFrom igraph neighborhood induced_subgraph
#' @export
SurfaceSearchlight <- function(surfgeom, radius=8, nodeset=NULL) {
  assertthat::assert_that(length(radius) == 1)
  g <- if (is.null(nodeset)) {
    ## use all surface nodes
    nodeset <- nodes(surfgeom)
    subgraph = FALSE
    neuroim::graph(surfgeom)
  } else {
    assertthat::assert_that(length(nodeset) > 1)
    subgraph=TRUE
    g <- igraph::induced_subgraph(neuroim::graph(surfgeom), nodeset)
  }
  
  bg <- neighborGraph(g, radius=radius)
  
  index <- 0
  
  nds <- V(bg)
  
  prog <- function() { index/length(nds) }
  
  getIndex <- function() { index }
  
  nextEl <- function() {
    if (index < length(nds)) {
      index <<- index + 1
      indices <- as.vector(igraph::neighborhood(bg, 1, nds[index])[[1]])
      
      if (subgraph) {
        ## index into to absolute graph nodes
        indices <- nodeset[indices]
        attr(indices, "center") <- nodeset[index]
        attr(indices, "center.index") <- nodeset[index]
        indices
      } else {
        attr(indices, "center") <- index
        attr(indices, "center.index") <- index
        indices
      }
      
    } else {
      stop('StopIteration')
    }
  }
  
  obj <- list(nextElem=nextEl, progress=prog, index=getIndex)
  class(obj) <- c("Searchlight", 'abstractiter', 'iter')
  obj
  
}


#' Create an exhaustive searchlight iterator
#' @param mask an image volume containing valid central voxels for roving searchlight
#' @param radius in mm of spherical searchlight
#' @export
Searchlight <- function(mask, radius) {
  mask.idx <- which(mask != 0)
	grid <- indexToGrid(mask, mask.idx)
	index <- 0
  
	prog <- function() { index/length(mask.idx) }
  
	nextEl <- function() {
		if (index < nrow(grid)) { 
			 index <<- index + 1
		 	 search <- RegionSphere(mask, grid[index,], radius, nonzero=TRUE) 
       vox <- coords(search)
			 attr(vox, "center") <- grid[index,]
			 attr(vox, "center.index") <- mask.idx[index]
       vox
		} else {
			stop('StopIteration')
		}
	}
	
	obj <- list(nextElem=nextEl, progress=prog)
  class(obj) <- c("Searchlight", 'abstractiter', 'iter')
	obj
			
}


#' @name as
#' @rdname as-methods
setAs(from="ROIVolume", to="DenseBrainVolume", function(from) {
  dat <- array(0, dim(from@space))
  dat[coords(from)] <- from@data
  ovol <- DenseBrainVolume(dat, from@space, from@source)
})


#' @rdname values-methods
#' @export 
setMethod("values", signature(x="ROIVolume"),
          function(x, ...) {
             x@data
          })


#' @rdname values-methods
#' @export 
setMethod("values", signature(x="ROISurface"),
          function(x, ...) {
            x@data
          })


#' @rdname indices-methods
#' @export 
setMethod("indices", signature(x="ROIVolume"),
          function(x) {
			  gridToIndex(x@space, x@coords)
		  })
            
#' @rdname indices-methods
#' @export 
setMethod("indices", signature(x="ROISurface"),
          function(x) {
            x@indices
          })


#' @export
#' @param real if \code{TRUE}, return coordinates in real world units
#' @rdname coords-methods
setMethod(f="coords", signature=signature(x="ROIVolume"),
          function(x, real=FALSE) {
            if (real) {
              input <- t(cbind(x@coords-.5, rep(1, nrow(x@coords)))) 
              ret <- t(trans(x) %*% input)
              ret[,1:3,drop=FALSE]
            } else {
              x@coords
            }
          })

#' @export
#' @rdname coords-methods
setMethod(f="coords", signature=signature(x="ROISurface"),
          function(x) {
            x@coords
          })

#' @export 
#' @rdname length-methods
setMethod(f="length", signature=signature(x="ROIVolume"),
          function(x) {
            nrow(x@coords)
          })



#' @export 
#' @rdname length-methods
#' @param x the object to get \code{length}
setMethod(f="length", signature=signature(x="ROISurface"),
          function(x) {
            length(x@indices)
          })


#' subset an \code{ROIVolume}
#' @export
#' @param x the object
#' @param i first index
#' @param j second index
#' @param drop drop dimension
#' @rdname vol_subset-methods
#' @aliases [,ROIVolume,numeric,missing,ANY-method
setMethod("[", signature=signature(x = "ROIVolume", i = "numeric", j = "missing", drop = "ANY"),
          function (x, i, j, drop) {
            if (is.matrix(x@data)) {
              ROIVolume(x@space, x@coords[i,,drop=FALSE], x@data[,i])
            } else {
              ROIVolume(x@space, x@coords[i,,drop=FALSE], x@data[i])
            }
          })

#' @rdname vol_subset-methods
#' @aliases [,ROIVolume,logical,missing,ANY-method
setMethod("[", signature=signature(x="ROIVolume", i="logical", j="missing", drop="ANY"),
          function(x,i,j,drop) {
            if (is.matrix(x@data)) {
              ROIVolume(x@space, x@coords[i,,drop=FALSE], x@data[,i])
            } else {
              ROIVolume(x@space, x@coords[i,,drop=FALSE], x@data[i])
            }
          })

#' @rdname vol_subset-methods
#' @aliases [,ROIVolume,numeric,numeric,ANY-method
setMethod("[", signature=signature(x="ROIVolume", i="numeric", j="numeric", drop="ANY"),
          function(x,i,j,drop) {
            if (is.matrix(x@data)) {
              ROIVolume(x@space, x@coords[i,,drop=FALSE], x@data[j,i,drop=drop])
            } else {
              stop("illegal subset: `data` is 1-dimensional")
            }
          })

#' @rdname vol_subset-methods
#' @aliases [,ROIVolume,missing,numeric,ANY-method
setMethod("[", signature=signature(x="ROIVolume", i="missing", j="numeric", drop="ANY"),
          function(x,i,j,drop) {
            if (is.matrix(x@data)) {
              ROIVolume(x@space, x@coords, x@data[j,,drop=drop])
            } else {
              stop("illegal subset: `data` is 1-dimensional")
            }
          })

#' @rdname vol_subset-methods
#' @aliases [,ROIVolume,missing,logical,ANY-method
setMethod("[", signature=signature(x="ROIVolume", i="missing", j="logical", drop="ANY"),
          function(x,i,j,drop) {
            if (is.matrix(x@data)) {
              ROIVolume(x@space, x@coords, x@data[j,,drop=drop])
            } else {
              stop("illegal subset: `data` is 1-dimensional")
            }
          })

#' @rdname vol_subset-methods
#' @aliases [,ROIVolume,logical,logical,ANY-method
setMethod("[", signature=signature(x="ROIVolume", i="logical", j="logical", drop="ANY"),
          function(x,i,j,drop) {
            if (is.matrix(x@data)) {
              ROIVolume(x@space, x@coords[i,,drop=FALSE], x@data[j,i,drop=drop])
            } else {
              ROIVolume(x@space, x@coords[i,,drop=FALSE], x@data[i])
            }
          })

#' subset an \code{ROISurface}
#' @export
#' @param x the object
#' @param i first index
#' @param j second index
#' @param drop drop dimension
#' @rdname surf_subset-methods
#' @aliases [,ROISurface,numeric,missing,ANY-method
setMethod("[", signature=signature(x = "ROISurface", i = "numeric", j = "missing", drop = "ANY"),
          function (x, i, j, drop) {
            if (is.matrix(x@data)) {
              ROISurface(x@geometry, x@indices[i], x@data[,i])
            } else {
              ROISurface(x@geometry, x@indices[i], x@data[i])
            }
          })

#' @rdname surf_subset-methods
#' @aliases [,ROISurface,numeric,numeric,ANY-method
setMethod("[", signature=signature(x = "ROISurface", i = "numeric", j = "numeric", drop = "ANY"),
          function (x, i, j, drop) {
            if (is.matrix(x@data)) {
              ROISurface(x@geometry, x@indices[i], x@data[j,i,drop=drop])
            } else {
              ROISurface(x@geometry, x@indices[i], x@data[i])
            }
          })

#' @rdname surf_subset-methods
#' @aliases [,ROISurface,missing,numeric,ANY-method
setMethod("[", signature=signature(x = "ROISurface", i = "missing", j = "numeric", drop = "ANY"),
          function (x, i, j, drop) {
            if (is.matrix(x@data)) {
              ROISurface(x@geometry, x@indices[i], x@data[j,i,drop=drop])
            } else {
              ROISurface(x@geometry, x@indices[i], x@data[i])
            }
          })

#' @rdname surf_subset-methods
#' @aliases [,ROISurface,logical,logical,ANY-method
setMethod("[", signature=signature(x = "ROISurface", i = "logical", j = "logical", drop = "ANY"),
          function (x, i, j, drop) {
            if (is.matrix(x@data)) {
              ROISurface(x@geometry, x@indices[i], x@data[j,i,drop=drop])
            } else {
              ROISurface(x@geometry, x@indices[i], x@data[i])
            }
          })

#' @rdname surf_subset-methods
#' @aliases [,ROISurface,logical,missing,ANY-method
setMethod("[", signature=signature(x = "ROISurface", i = "logical", j = "missing", drop = "ANY"),
          function (x, i, j, drop) {
            if (is.matrix(x@data)) {
              ROISurface(x@geometry, x@indices[i], x@data[,i])
            } else {
              ROISurface(x@geometry, x@indices[i], x@data[i])
            }
          })


#' show an \code{\linkS4class{ROIVolume}} 
#' @param object the object
#' @export
setMethod("show", signature=signature(object = "ROIVolume"),
		  function (object) {
			  cat("\n\n\tROIVolume", "\n")
			  cat("\t size: ", length(object), "\n")
			  cat("\t parent dim:", dim(object), "\n")
			  cat("\t num data cols:", if (is.matrix(object@data)) ncol(object@data) else 1, "\n" )
			  cat("\t voxel center of mass: ", colMeans(coords(object)), "\n")
		  })

#' show an \code{\linkS4class{ROISurface}} 
#' @param object the object
#' @export
setMethod("show", signature=signature(object = "ROISurface"),
          function (object) {
            cat("\n\n\tROISurface", "\n")
            cat("\tsize: ", length(object@indices), "\n")
            cat("\tdata type:", if (is.matrix(object@data)) "matrix" else "vector", "\n" )
            cat("\tdata dim:", if (is.matrix(object@data)) dim(object@data) else length(object@data), "\n" )
            cat("\tvertex center of mass: ", colMeans(object@coords), "\n")
          })

  
      
.distance <- function(p1, p2) {
  diffs = (p1 - p2)
  sqrt(sum(diffs*diffs))
}


#' Create a Kernel object
#' @param kerndim the dimensions in voxels of the kernel
#' @param vdim the dimensions of the voxels in real units
#' @param FUN the kernel function taking as its first argument representing the distance from the center of the kernel
#' @param ... additional parameters to the kernel FUN
#' @importFrom stats dnorm
#' @export
Kernel <- function(kerndim, vdim, FUN=dnorm, ...) {
  if (length(kerndim) < 2) {
    stop("kernel dim length must be greater than 1")
  }
  
  #kern <- array(0, kerndim)
  
  ## the half-width for each dimensions
  hwidth <- sapply(kerndim, function(d) ceiling(d/2 -1))
  
  ## note, if a kernel dim is even, this will force it to be odd numbered
  grid.vec <- lapply(hwidth, function(sv) seq(-sv, sv))

  # compute relative voxel locations (i.e. centered at 0,0,0)
  voxel.ind <- as.matrix(do.call("expand.grid", grid.vec))
  
  # fractional voxel locations so that the location of a voxel coordinate is centered within the voxel
  cvoxel.ind <- t(apply(voxel.ind, 1, function(vals) sign(vals)* ifelse(vals == 0, 0, abs(vals)-.5)))
  
  ## the coordinates ofthe voxels (i.e. after multiplying by pixel dims)
  coords <- t(apply(cvoxel.ind, 1, function(v) (v * vdim)))
  
  ## distance of coordinate from kernel center
  coord.dist <- apply(coords, 1, .distance, c(0,0,0))
  
  wts <- FUN(coord.dist, ...)
  wts <- wts/sum(wts)

  
  kern.weights <- wts
  
  new("Kernel", width=kerndim, weights=kern.weights, voxels=voxel.ind, coords=coords)

}



#' @param centerVoxel the absolute location of the center of the voxel, default is (0,0,0)
#' @rdname voxels-methods
#' @export
setMethod(f="voxels", signature=signature(x="Kernel"),
          function(x, centerVoxel=NULL) {
            if (is.null(centerVoxel)) {
              x@voxels
            } else {
              sweep(x@voxels, 2, centerVoxel, "+")
            }
          })


  

  
