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