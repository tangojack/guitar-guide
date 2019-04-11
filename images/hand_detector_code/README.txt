HAND Detector
==== ========

Author: A. Mittal, A. Zisserman and  P. H. S. Torr
Copyright: Arpit Mittal
Last updated: 15/05/2012


Licence
-------
THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

This software is a hand detector for static images, designed mainly for human layout estimation and
described in detail in [1].

This software is free ONLY for research purposes. If you want to use any part of the code you
should cite this publication.


Dependencies
------------
This code requires parts-based model [2,3], SVM-light toolbox [4], Berkeley super-pixel segmentation code [5]
and a face-detector (we used OpenCV face detector).
We provide a script which will download and install parts-based model [2,3] and SVM-light [4].
It will be required by the user to download and install Berkeley super-pixel segmentation code [5] and 
also to generate the face detection results. We provide a wrapper function 'process_gPb' in the root directory, 
which will call the segmentation routines of [5] and store the super-pixels at appropriate location. 
The face detections are to be stored at 'data/faceboxes' in the format specified in the README file in that folder.


Installation and Contents
------------ --- --------
This package contains a MATLAB implementation of the hand detection system described in [1].

After downloading the file, untar it. This would create a directory structure consisting of the following folders:
- code (Constains all the code)
- data (Contains all the data)
- trained_models (The trained models for hand shape and context detectors).

1) Run setup.m. This will download and install the parts-based model [2] and the faster cascaded version
of the same code [3]. It will also install the svm-light toolbox [4]. To do so, the internet connectivity is 
required. Furthermore, if you get any errors while running this file, check if the Urls mentioned in the file 
are active.

2) Install Berkeley super-pixel segmentation code [5], run process_gPb.m to save the super-pixel segmentation results.

3) Save the face detection results for the test images stored at 'data/images' in the folder 'data/faceboxes'

4) Run demo.m, which will run a demo code over 3 test images stored at 'data/images'. 
For the demo code, we are providing the super-pixel segmentations and face detections with this package. Hence, steps 
2 and 3 could be ignored.

This software could be used with any version of MATLAB (preferably >= 2007) with the image-processing toolbox.


Usage
-----
See demo.m


Support
-------
For any query/suggestions, please drop an email to the following address:
arpit@robots.ox.ac.uk


References
----------
[1] Hand detection using multiple proposals
Mittal, A., Zisserman, A. and Torr, P. H. S.
Proceedings of British Machine Vision Conference, 2011.

[2] Discriminatively trained deformable part models, Release 4
Felzenszwalb, P. F. and Girschick, R. B. and McAllester, D.
http://people.cs.uchicago.edu/~pff/latent-release4/

[3] Cascade object detection with deformable part models
Felzenszwalb, P. F. and Girschick, R. B. and McAllester, D.
Proceedings of Computer Vision and Pattern Recognition Conference, 2010.

[4] Making large-scale SVM learning practical
Joachims, T.
Advances in kernel methods - support vector learning, MIT Press, 1999.
http://svmlight.joachims.org/

[5] Contour detection and hierarchical image segmentation
Arbelaez, P. and Maire, M. and Fowlkes, C. and Malik, J.
IEEE Transaction of PAMI, May 2011.
http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/resources.html
