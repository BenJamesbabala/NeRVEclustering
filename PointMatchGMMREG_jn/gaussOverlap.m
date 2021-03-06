function  [f, g]= gaussOverlap(A,B,scales,peaks,limit)


%Jeff N's version of the mex_GaussTransform from GMM mixturemodel code. I'm
%adding possibility to change scales and making it more transparent. The
%code takes point sets A and B, puts a gaussian at each position of with
%standard deviation given by scale, and then calculates the inner product.
%NOTE: this is not the full inner product as it skips the prefactor in
%front of the exponential term. This makes it so that the inner product of
%a gaussian with itself is 1. This is done to match the mex program
%exactly. Speed is now slightly faster than mex_GaussTransform

% inputs:   A pointset of scene, If A is n*3, scales and peaks are
% specified sepearately in inputs. if A is n*4, the 4th D is the scales, if A is n*5,
% 5th D is the peaks 
%           B pointset of model, same format as A;
%           scale is the variances of each point. if it is scalar, all
%           points will have the same varaince, if it is a cell, the first
%           cell will be the scales for the points in A, the second will be
%           the scales for the points in B

% outputs : f total overlap integrals
%            g gradient in energy of the points in A
   
Apoints=size(A,1);Bpoints=size(B,1);
nPoints=Apoints*Bpoints;


if nargin<5
    limit=30; %should normally be Inf
end
if nargin<4
    if size(A,2)>4
        peaksA=A(:,5);
        peaksB=B(:,5);
        peaksA=peaksA/sum(peaksA);
        peaksB=peaksB/sum(peaksB);
        peaksMat=bsxfun(@times, peaksA,peaksB');

    else
    peaksMat=1/nPoints;
    end
else
            peaksA=peaks{1};peaksB=peaks{2};

    peaksMat=bsxfun(@times, peaksA,peaksB');
end
if ~iscell(scales)
        if size(A,2)>3
        scaleA=A(:,4)*scales;
        scaleB=B(:,4)*scales;
        varMat=bsxfun(@plus,scaleA.^2,(scaleB').^2);

        else
    varMat=2*scales.^2;
        end
    
else

     varMat=bsxfun(@plus,scales{1}.^2,(scales{2}').^2);
end


A1=A(:,1:3);B1=B(:,1:3);
A1=permute(A1,[1,3,2]);B1=permute(B1,[3,1,2]);
dmatAll=bsxfun(@minus,A1,B1);
dmat2=sum(dmatAll.^2,3);


%% overlap of gaussians is a gaussian of the distance with variance as the sum
% of variances

% gradient of that overlap (d expMat/ dA) is force

 %expMat=peaksMat./sqrt(2*pi*varMat).*exp(-1/2 * dmat.^2./varMat);
  expMat=peaksMat.*exp(-2 * dmat2./varMat);
if ~isinf(limit)
expMat(dmat2>limit.^2)=0;
end
    f=sum(expMat(:));

expMat2=-(4./(varMat)).*expMat;
fmat=bsxfun(@times,expMat2,dmatAll);
g=reshape(sum(fmat,2),Apoints,3);





