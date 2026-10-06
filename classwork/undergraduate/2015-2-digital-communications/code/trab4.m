
hMod = comm.PAMModulator(2);
hRCTxFilter = comm.RaisedCosineTransmitFilter(...
'Shape','Normal', ...
'RolloffFactor',0.5, ...
'FilterSpanInSymbols',Rup, ...
'OutputSamplesPerSymbol',Rup);
Rup = 64; % upsampling rate
%número de bit = ndBit
ndBit=100000;
data = (ones(ndBit,1)+sign(rand(ndBit,1)-0.5))/2;
modData = step(hMod, data);
hScope = comm.ConstellationDiagram('SamplesPerSymbol',Rup);
txSig = step(hRCTxFilter,modData);
gain = 1/max(hRCTxFilter.coeffs.Numerator);
txSig = gain*step(hRCTxFilter,modData);
step(hScope,txSig);
%hScope.ShowReferenceConstellation = false;
%rcv = awgn(txSig,10,'measured');
%step(hScope,rcv)
%hScope.ShowReferenceConstellation = false;
rcv = awgn(txSig,20,'measured');
%step(hScope,rcv)
%Eb/No = EbNo
EbNo=[0.1:100]/10;
c=0;
for a=1:100
    arcv=awgn(txSig,EbNo(a),'measured');
    arcvd=downsample(arcv,Rup);
    txSigD=downsample(txSig,Rup);
    for b=1:ndBit
        if txSigD(b)>0
            if arcvd(b)<0
                c =c+1;
            end
        end
        if txSigD(b)<0
            if arcvd(b)>0
                c =c+1;
            end
        end
    end
    ber100k(a)=c/ndBit
    c=0;
end

ndBit2 = 10000;
data2 = (ones(ndBit2,1)+sign(rand(ndBit2,1)-0.5))/2;
modData2 = step(hMod, data2);
gain2 = 1/max(hRCTxFilter.coeffs.Numerator);
txSig2 = gain2*step(hRCTxFilter,modData);
for a=1:100
    arcv=awgn(txSig2,EbNo(a),'measured');
    arcvd=downsample(arcv,Rup);
    txSigD=downsample(txSig2,Rup);
    for b=1:ndBit2
        if txSigD(b)>0
            if arcvd(b)<0
                c =c+1;
            end
        end
        if txSigD(b)<0
            if arcvd(b)>0
                c =c+1;
            end
        end
    end
    ber10k(a)=c/ndBit2
    c=0;
end


ndBit3 = 1000;
data3 = (ones(ndBit3,1)+sign(rand(ndBit3,1)-0.5))/2;
modData3 = step(hMod, data3);
gain3 = 1/max(hRCTxFilter.coeffs.Numerator);
txSig3 = gain3*step(hRCTxFilter,modData);
for a=1:100
    arcv=awgn(txSig3,EbNo(a),'measured');
    arcvd=downsample(arcv,Rup);
    txSigD=downsample(txSig3,Rup);
    for b=1:ndBit3
        if txSigD(b)>0
            if arcvd(b)<0
                c =c+1;
            end
        end
        if txSigD(b)<0
            if arcvd(b)>0
                c =c+1;
            end
        end
    end
    ber1k(a)=c/ndBit3
    c=0;
end
figure; plot(EbNo,ber100k,EbNo,ber10k,EbNo,ber1k);
