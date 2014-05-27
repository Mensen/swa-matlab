/* Derived from stream3c.c from MATLAB R2011a */

#include <math.h>
#include <stdlib.h>
#include <memory.h>
#include "mex.h"

unsigned long nanAlt[2] = {0xffffffff, 0x7fffffff};

/* Input Arguments */

#define	X_IN	    prhs[0]
#define	Y_IN	    prhs[1]
#define	U_IN	    prhs[2]
#define	V_IN	    prhs[3]
#define	SX_IN	    prhs[4]
#define	SY_IN	    prhs[5]
#define COSMIN_IN   prhs[6]
#define	STEP_IN	    prhs[7]
#define	MAXVERT_IN  prhs[8]

#ifndef NULL
#define NULL 0
#endif

/* Output Arguments */

#define	V_OUT plhs[0]
#define D_OUT plhs[1]
#define C_OUT plhs[2]

double *verts = NULL, *dists = NULL, *cosines = NULL;

void cleanup()
{
    if (verts)
      mxFree(verts);    
    if (dists)
      mxFree(dists);    
    if (cosines)
      mxFree(cosines);    
}

#define GETX2(X) xvec[(X)]
#define GETY2(Y) yvec[(Y)]

#define GETU2(X,Y) ugrid[(Y) + ydim*(X)]
#define GETV2(X,Y) vgrid[(Y) + ydim*(X)]

/*
 * 2D streamline(x,y,u,v,sx,sy)
 */
int
traceStreamXYUV(double *xvec, double *yvec, 
				double *ugrid, double *vgrid, 
				mwSize xdim, mwSize ydim, 
				double sx, double sy,
				double cosMin, 
				double step, int maxVert)
{
    int numVerts = 0;
    double x = sx-1, y = sy-1; /* so here x and y actually become the starting points of the streamline */
    mwSize ix, iy;
    double x0,x1,y0,y1,xiPrev = 0,yiPrev = 0,xi,yi,dx,dy;
    double xfrac, yfrac, ui, vi, uiPrev, viPrev;
    double a,b,c,d, imax;
    double ax, ay, bx, by, nf, cos;
	
	if ((verts = mxMalloc(2 * maxVert * sizeof(double))) == NULL)
	  {
		  cleanup();
		  mexErrMsgIdAndTxt("MATLAB:adstream2:InsufficientMemoryForVertices",
							"Not enough memory to store vertices");
	  }
	
	if ((dists = mxMalloc(maxVert * sizeof(double))) == NULL)
	  {
		  cleanup();
		  mexErrMsgIdAndTxt("MATLAB:adstream2:InsufficientMemoryForDistances",
							"Not enough memory to store distances");
	  }
	
	if ((cosines = mxMalloc(2 * maxVert * sizeof(double))) == NULL)
	  {
		  cleanup();
		  mexErrMsgIdAndTxt("MATLAB:adstream2:InsufficientMemoryForCosines",
							"Not enough memory to store cosines");
	  }
    
    xi = 0; /* Pau says strange... superfluous */
    yi = 0;
    
    bx = 0;
    by = 0;
    
    while(1) /* Keep going forever... so... until some break is reached */
		{
			if (numVerts>=maxVert)
            {
                mexWarnMsgIdAndTxt("MATLAB:adstream2:MaxNumVertices",
                                   "adstream2 should not have been able to reach the maximum number of vertices.");
                break;
            }
          
			if (x<0 || x>xdim-1 || y<0 || y>ydim-1) /* This prevents negative starting points or points over the edge on the grid... */
			{
				break;
			}
          
			if (mxIsNaN(x)) { ix = 0; } else  { ix = (mwSize)x;} /* because of the mwSize cast, ix is not necessarily x here but just the integer (0.9 = 0)! So it can be used to index... */
			if (mxIsNaN(y)) { iy = 0; } else  { iy = (mwSize)y;} /* although ix = 0 when x = 1.00, but ix = 2 when x = 2.00... strange behaviour */
			
			/* ix always attempts to be one left and below the current point (unless cp is 1,1) */
			
			if (ix==xdim-1) ix--; /* if its at the edge of the map, go back 1 */
			if (iy==ydim-1) iy--;
			xfrac = x-ix; /* this is the fraction of x not also represented in ix... */
			yfrac = y-iy; /* becomes a NaN when x/y is NaN when ui or vi is NaN */			  
		  
			x0 = GETX2(ix); x1 = GETX2(ix+1); 	/* See define GETX2(X) xvec[(X)], so this gets the first and second values of the xrange input... */
			y0 = GETY2(iy); y1 = GETY2(iy+1); 	/* Same as with the xvec */
			
			xi = x0*(1-xfrac) + x1*xfrac;		/* Is NaN when x / y is NaN (so frac becomes NaN) */
			yi = y0*(1-yfrac) + y1*yfrac;
		  
			if (mxIsNaN(xi) || mxIsNaN(yi)) 	/* Check whether these are NaN, most common stop */
			{		
				break;
			}
			
			ax = bx;
			ay = by;
          
			bx = xi - xiPrev; /* change in xi... xi is the exact current point (vertex) */
			by = yi - yiPrev; 

			dists[numVerts] = sqrt(bx * bx + by * by); /* distance between this point and last point... */
                
			nf = 1 / dists[numVerts];
			bx *= nf;
			by *= nf;
          
			cosines[2*numVerts + 0] = bx;
			cosines[2*numVerts + 1] = by;
          
			cos = ax * bx + ay * by; /* calculate current angle step */
		  
			/* mexPrintf("\nCurrent dists value %f \n", dists[numVerts]); */
          
			if ((cos <= cosMin) && (numVerts >= 2)) /* breaks when angle is more than 45d (or special input) */
            {
                numVerts--;
			    /* mexPrintf("Broke here because cos (change in gradient angle) is... %f \n", cos);
				mexPrintf("ax = %f, bx = %f, ay = %f, by = %f \n", ax,bx,ay,by);
				mexPrintf("x is %f, y is %f \n", x, y);						
				mexPrintf("ix, is %d, and iy is %d \n", ix, iy);
				mexPrintf("xi, xiPrev is %f,%f, yi, yiPrev is %f,%f \n", xi, xiPrev, yi, yiPrev);
				mexPrintf("xfrac is %f, yfrac is %f \n", xfrac, yfrac);
				mexPrintf("xi, xiPrev is %f,%f, yi, yiPrev is %f,%f \n", xi, xiPrev, yi, yiPrev);
				mexPrintf("ui, uiPrev is %f,%f, vi, viPrev is %f,%f \n", ui, uiPrev, vi, viPrev);				
			        mexEvalString("drawnow;"); to dump string. */ 					
				break;
            }
          
			verts[2*numVerts + 0] = xi; /* current vertex locations saved for output */
			verts[2*numVerts + 1] = yi;
			numVerts++;					/* go to the vertex */
		  
			xiPrev = xi; 				/* record 'previous' location */
			yiPrev = yi;
		  
			a=(1-xfrac)*(1-yfrac); /* essentially a weight to calculate how much of current ui value used */
			b=(  xfrac)*(1-yfrac); /* weight for right ui value */
			c=(1-xfrac)*(  yfrac); /* weight for ui value below */
			d=(  xfrac)*(  yfrac); /* weight for ui vaue below and to the right */
		  
			/* mexPrintf("\n a = %f, b = %f, c = %f, d = %f \n", a,b,c,d); */
			/* mexEvalString("drawnow;"); to dump string. */
			
			uiPrev = ui;
			viPrev = vi;
			
			ui = 
				GETU2(ix,  iy  )*a + GETU2(ix+1,iy  )*b + 
				GETU2(ix,  iy+1)*c + GETU2(ix+1,iy+1)*d;  /* a more accurate (interpolated) ui value based on ugrid of point and surrounding */
			vi = 
				GETV2(ix,  iy  )*a + GETV2(ix+1,iy  )*b +
				GETV2(ix,  iy+1)*c + GETV2(ix+1,iy+1)*d;
			
			if (mxIsNaN(ui) || mxIsNaN(vi))  /* break if gradients have NaNs */
			{
				/* mexPrintf("Broke here because a gradient was found to be NaN \n"); */	
				/* mexEvalString("drawnow;"); */
				break;
			}

			if (fabs(ui)==0) ui = uiPrev;
			if (fabs(vi)==0) vi = viPrev;
						
			dx = x1-x0; /* differential between adjacent points in the xrange */
			dy = y1-y0; /* differential between adjacent points in the yrange */
			if (dx) ui /= dx; /* How could (dx) ever be zero? */
			if (dy) vi /= dy; /* gradient information divided by the difference between adjacent grid points (Riedner always has 1) */
		  
			if (fabs(ui)>fabs(vi)) imax=fabs(ui); else imax=fabs(vi); /*imax is the bigger gradient between horizontal and vertical gradients */
			if (imax==0) 
			{
				/* mexPrintf("Broke here because imax (max h/v gradient) is %f \n", imax); */
				/* mexEvalString("drawnow;"); */				
				break; /* if gradient is zero then break... this is bad because various sampling rates or large interpolants may make intermittent zero gradients where stream would stop */
			}
		  
			imax = step/imax; /* divide stepsize by the max gradient, why? */				
			
			ui *= imax; /* by multiplying by the new imax, its really just multiplying by the stepsize */
			vi *= imax;
			
			x += ui; /* next x point will be to the left if u-gradient is negative... */
			y += vi;
      }
    
    return(numVerts);
}

void mexFunction(int nlhs, 
                 mxArray *plhs[], 
                 int nrhs, 
                 const mxArray *prhs[])
{
    double *x, *y, *u, *v, *sx, *sy, *cosMin, *step, *maxVert;
    mwSize xSize, ySize;
    double *vOut, *dOut, *cOut;
    const mwSize *dims;
    int numVerts;
    
    /* Check for proper number of arguments */
    
    if (nrhs != 9) 
      mexErrMsgIdAndTxt("MATLAB:adstream2:WrongNumberOfInputs",
                        "adstream2 requires 9 input arguments. [verts dists cosines] = adstream2( x,y, u,v, sx,sy, cosMin, step, maxVert )");
    if (nlhs != 3) 
      mexErrMsgIdAndTxt("MATLAB:adstream2:WrongNumberOfOutputs",
                        "adstream2 requires 3 output arguments. [verts dists cosines] = adstream2( x,y, u,v, sx,sy, cosMin, step, maxVert )");
    
    x = mxGetPr( X_IN ); /* Pointers are just addresses, not the actual data */
    y = mxGetPr( Y_IN );
    u = mxGetPr( U_IN );
    v = mxGetPr( V_IN );
    sx = mxGetPr( SX_IN );
    sy = mxGetPr( SY_IN );
    cosMin  = mxGetPr( COSMIN_IN  );
    step    = mxGetPr( STEP_IN    );
    maxVert = mxGetPr( MAXVERT_IN );
    
    dims = mxGetDimensions(U_IN);
    xSize = dims[1];
    ySize = dims[0];
    if (xSize <= 1 || ySize <= 1) 
      mexErrMsgIdAndTxt("MATLAB:adstream2:WrongDimensionSizes",
                        "adstream2 requires that both dimensions be greater than 1");
	
	numVerts = traceStreamXYUV(x,y,u,v,xSize, ySize, *sx, *sy, *cosMin, *step, (int)(*maxVert));
	
    /* Create matrices for the return arguments */
    if (numVerts > 1)
      {
          V_OUT = mxCreateDoubleMatrix( 2, numVerts,   mxREAL );
          D_OUT = mxCreateDoubleMatrix( 1, numVerts - 1,   mxREAL );
          C_OUT = mxCreateDoubleMatrix( 2, numVerts,   mxREAL );
          
          /* Assign pointers to the various parameters */
          vOut = mxGetPr( V_OUT );
          dOut = mxGetPr( D_OUT );
          cOut = mxGetPr( C_OUT );
          
          /* copy the results into the output parameters*/
          memcpy((char *)vOut, (char *)verts, numVerts*2*sizeof(double));
          memcpy((char *)dOut, (char *)&dists[1], (numVerts - 1)*sizeof(double));
          memcpy((char *)cOut, (char *)cosines, numVerts*2*sizeof(double));
          
          cOut[0] = *(double *)nanAlt;
          cOut[1] = *(double *)nanAlt;
          cOut[2] = *(double *)nanAlt;
      }
    else
      {
          V_OUT = mxCreateDoubleMatrix( 0, 0,   mxREAL );
          D_OUT = mxCreateDoubleMatrix( 0, 0,   mxREAL );
          C_OUT = mxCreateDoubleMatrix( 0, 0,   mxREAL );
      }
    
    cleanup();
}
