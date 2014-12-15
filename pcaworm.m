xAll=[];tAll=[];
nFiducials=17;

hasPoints=cellfun(@(x) ~isempty(x{1}), fiducialPoints,'uniformoutput',0);
hasPoints=find(cell2mat(hasPoints));
nTimes=length(hasPoints);
for ii=1:nTimes
    i=hasPoints(ii);
%x=(cell2mat(cellfun(@(x) x{:,1}, fiducialPoints(i),'uniformoutput',0)));
x=(fiducialPoints{i});
if(size(x,1))>=nFiducials && size(x,2)>2
x=x(1:nFiducials,1:2);
x(cellfun(@(x) isempty(x),x))={nan};
x=cell2mat(x);
X2=(pdist(x));
if i==hasPoints(1)
    X0=nan(size(X2));
end


    xAll=cat(1,xAll,X2);
    tAll=cat(1,tAll,i);
else
    xAll=cat(1,xAll,X0);
        tAll=cat(1,tAll,i);

end


end
%%
xmeans=nanmean(xAll,1);
%xmeans=xAll(50,:);
xSTDs=nanstd(xAll,[],1);
zAll=bsxfun(@minus, xAll,xmeans);
zAll=bsxfun(@rdivide, zAll,xSTDs);

[coeff,score,latent,tsquared,explained,mu] = pca(zAll);
coeff2=bsxfun(@times, coeff,xSTDs');
coeff2=bsxfun(@plus, coeff2,xmeans');


%%

vols=size(Rcrop,5);
RvalsAll=zeros(vols,nTimes);
GvalsAll=RvalsAll;

progressbar(0,0);
for iVol=1:vols
    for i=1:nTimes
        iTime=hasPoints(i);
        progressbar(iVol/vols,iTime/nTimes);
        subVolumeR=pedistalSubtract(Rcrop(:,:,:,iTime,iVol));
        subVolumeG=(Gcrop(:,:,:,iTime,iVol))-90;
        subVolumeG(subVolumeG<0)=0;
        subBW=normalizeRange(subVolumeR)>.5;
        cc=bwconncomp(subBW,6);
        nPixRegions=cell2mat(cellfun(@(x) length(x), cc.PixelIdxList,'uniformOutput',0));
        [~,areaIdx]=max(nPixRegions);
        Rvals=subVolumeR(cell2mat(cc.PixelIdxList(areaIdx)'));
        Gvals=subVolumeG(cell2mat(cc.PixelIdxList(areaIdx)'));
        
        RvalsAll(iVol,i)=nanmean(Rvals);
        GvalsAll(iVol,i)=nanmean(Gvals);
    end
end

%%
RvalsAll(RvalsAll==0)=nan;
GvalsAll(GvalsAll==0)=nan;

R2=bsxfun(@rdivide,RvalsAll,nanmedian(RvalsAll,2));
G2=bsxfun(@rdivide,GvalsAll,nanmedian(GvalsAll,2));
% R2=RvalsAll;
% G2=GvalsAll;
R2smooth=smooth2a(R2(:,1:nTimes),0,1);%-smooth2a(R2(:,1:nTimes),0,80);
G2smooth=smooth2a(G2(:,1:nTimes),0,1)-smooth2a(G2(:,1:nTimes),0,80);

A=(G2smooth./R2smooth)';
%A=[A score(1:size(A,1),1:3)];
%A=G2smooth';

A=bsxfun(@minus, A,quantile(A,.2,1));
A=bsxfun(@rdivide,A,nanstd(A,[],1));
A(A<-1)=-nan;
acorr=corr(A);
atemp=nancov(A)./sqrt(nanvar(A)'*nanvar(A));
acorr(isnan(acorr))=atemp(isnan(acorr));

cg = clustergram(acorr);
cgIdx=str2double(get(cg,'RowLabels'));
%cgIdx=cgIdx(cgIdx<(max(cgIdx)-2));
A=A';
figure

imagesc(linspace(0,Ntimes*.2,Ntimes),1:length(cgIdx),A(cgIdx,:));
figure
subplot(2,1,1);imagesc(R2smooth(cgIdx,:));subplot(2,1,2);imagesc(G2smooth(cgIdx,:));



%%
%reversalTimes=[5:13 41:57 81:87 110:120 160:170];
behaviorTrack=hiResBehavior(hasPoints);
reversalTimes=find(behaviorTrack<1);
notReversalTimes=(behaviorTrack>0);
Ar=A(:,reversalTimes);
ANr=A(:,notReversalTimes);
ARmean=mean(Ar,2);
ARstd=nanstd(Ar,[],2);
ARCI=ARstd./length(reversalTimes)*4*1.28;
ANRmean=nanmean(ANr,2);
ANRstd=nanstd(ANr,[],2);
ANRCI=ANRstd./length(notReversalTimes)*4*1.28;
meanDiff=[nanmean(Ar,2) - nanmean(ANr,2)];

possibleR=find((meanDiff)>.2);

%%
figure
for i=1:length(possibleR)
plot(A(possibleR(i),:)'+5*i)
hold on
end
 area(hiResBehavior(hasPoints))

%plot(reversalTimes,repmat(0,1,length(reversalTimes)),'x')
%%
figure
space=5;
for i=1:length(possibleR)
    Rz=bsxfun(@minus, R2smooth,quantile(R2smooth,.2,2));
Rz=bsxfun(@rdivide,Rz,nanstd(Rz,[],2));

    Gz=bsxfun(@minus, G2smooth,quantile(G2smooth,.2,2));
Gz=bsxfun(@rdivide,Gz,nanstd(Gz,[],2));
% nanmap=(Rz<-1 | Gz<-1);
% Gz(Gz<-1)=nan;
% Rz(Rz<-1)=nan;
plot(Rz(possibleR(i),:)'+(i-1)*space,'r')

hold on
plot(Gz(possibleR(i),:)'+(i-1)*space,'black')

end
% plot(behavior>0,repmat(0,1,length(behavior)),'gx')
% plot(behavior>0,repmat(0,1,length(reversalTimes)),'gx')
% plot(behavior==0,repmat(0,1,length(reversalTimes)),'yellowx')
% 
area(hiResBehavior(hasPoints))

%%
figure
for i=1:length(possibleR)
plot(G2smooth(possibleR(i),:)'+(i-1),'black')
hold on
end
plot(reversalTimes,repmat(0,1,length(reversalTimes)),'x')


%%
for i=1:200;
    points=cell2mat(fiducialPoints{i});
    plot(points(:,1),points(:,2),'o');

    axis equal
        xlim([0,600]);
    ylim([0,600]);
    pause(.2);
    
end

for ii=1:length(hasPoints)
    i=hasPoints(ii);
    if i>767
    temp=fiducialPoints{i};
temp(5:6,:)=temp([6 5],:);
fiducialPoints{i}=temp;
    temp=fiducialPoints{i};
end
end
