/* This file is part of the program ept_ResultViewer.
// ept_ResultViewer is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// ept_ResultViewer is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with ept_ResultViewer.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "math.h"
#include "mex.h"
#include <stdlib.h>

#ifdef OPENMP
#include "omp.h"
#endif

#ifndef MAX
#define MAX(A,B) ((A) > (B) ? (A) : (B))
#endif

#ifndef MIN
#define MIN(A,B) ((A) > (B) ? (B) : (A))
#endif

void tfce_thread(double *inData, double *outData, double *ChN, double *thresh, const int *dims, const int *dims2)
{
   double valToAdd;
   int i, t, ti, tt, maxt, mint, temp, growingInd, growingCur, ChCurr, idx, n=0;
   int numVoxels = dims[0] * dims[1];
   char* flagUsed;
   short* grow_i;
   short* grow_t;

   flagUsed = (char*)malloc(numVoxels*sizeof(char));
   grow_i  = (short*)malloc(numVoxels*sizeof(short));
   grow_t  = (short*)malloc(numVoxels*sizeof(short));


    for (temp = 0; temp < numVoxels; ++temp) flagUsed[temp] = 0;

	for (t = 0; t < dims[1]; ++t)
	{
		for (i = 0; i < dims[0]; ++i)
		{
			temp = (t*dims[0]) + i;
			if (!flagUsed[temp] && inData[temp] >= thresh[0])
			{
				flagUsed[temp] = 1;
				growingInd = 1;
				growingCur = 0;
				grow_i[0]=i;
				grow_t[0]=t;
				n++;

				while (growingCur < growingInd)
				{
				   maxt = MIN(dims[1], grow_t[growingCur] + 2);
				   mint = MAX(0, grow_t[growingCur] - 1);

					for (tt = mint; tt < maxt; ++tt)
					{
						for (ti = 0; ti < dims2[1]; ++ti)
						{
							idx = (ti*dims2[0]) + grow_i[growingCur];
							ChCurr = ChN[idx];

							if (ChCurr == 0)
							{
								break;
							}

							ChCurr = ChCurr - 1;

							temp = (tt*dims[0]) + ChCurr;

							if (!flagUsed[temp] && inData[temp] >= thresh[0])
							{
								flagUsed[temp] = 1;
								grow_i[growingInd] = ChCurr;
								grow_t[growingInd] = tt;
								growingInd++;
							}
						}
					}
				   growingCur++;

				}
				growingCur = 0;

				valToAdd = n;

				while (growingCur < growingInd)
				{
				   outData[(grow_t[growingCur]*dims[0]) + grow_i[growingCur]] += valToAdd;
				   growingCur++;
				}
			}
		}
	}

   free(flagUsed);
   free(grow_i);
   free(grow_t);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

/* Declarations */
double *inData, *outData, *ChN, *thresh;
int ndim, ndim2;
const int *dims, *dims2;

/* check inputs */
if (nrhs!=3)
  mexErrMsgTxt("3 inputs required.");
else if (nlhs>2)
  mexErrMsgTxt("Too many output arguments.");

if (!mxIsDouble(prhs[0]))
	mexErrMsgTxt("First argument must be double.");

/* get input inDatage */
inData = (double*)mxGetPr(prhs[0]);
ChN    = (double*)mxGetPr(prhs[1]);
thresh = (double*)mxGetPr(prhs[2]);

ndim = mxGetNumberOfDimensions(prhs[0]);
ndim2 = mxGetNumberOfDimensions(prhs[1]);
if (ndim!=2 || ndim2!=2)
  mexErrMsgTxt("Inputs should be 2D");

dims = mxGetDimensions(prhs[0]);
dims2 = mxGetDimensions(prhs[1]);

/*Allocate memory and assign output pointer*/
plhs[0] = mxCreateNumericArray(ndim,dims,mxDOUBLE_CLASS, mxREAL);

/*Get a pointer to the data space in our newly allocated memory*/
outData = mxGetPr(plhs[0]);

tfce_thread(inData, outData, ChN, thresh, dims, dims2);

return;
}

