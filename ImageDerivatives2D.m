function J=ImageDerivatives2D(I,sigma,type)
% Gaussian based image derivatives
%
%  J=ImageDerivatives2D(I,sigma,type)
%
% inputs,
%   I : The 2D image
%   sigma : Gaussian Sigma
%   type : 'x', 'y', 'xx', 'xy', 'yy'
%
% outputs,
%   J : The image derivative
%
% Function is written by D.Kroon University of Twente (July 2010)
% $$$ Copyright (c) 2010, Dirk-Jan Kroon
% $$$ All rights reserved.
% $$$ 
% $$$ Redistribution and use in source and binary forms, with or without 
% $$$ modification, are permitted provided that the following conditions are 
% $$$ met:
% $$$ 
% $$$     * Redistributions of source code must retain the above copyright 
% $$$       notice, this list of conditions and the following disclaimer.
% $$$     * Redistributions in binary form must reproduce the above copyright 
% $$$       notice, this list of conditions and the following disclaimer in 
% $$$       the documentation and/or other materials provided with the distribution
% $$$       
% $$$ THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% $$$ AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% $$$ IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% $$$ ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% $$$ LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% $$$ CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% $$$ SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% $$$ INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% $$$ CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% $$$ ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% $$$ POSSIBILITY OF SUCH DAMAGE.


% Make derivatives kernels
[x,y]=ndgrid(floor(-3*sigma):ceil(3*sigma),floor(-3*sigma):ceil(3*sigma));

switch(type)
    case 'x'
        DGauss=-(x./(2*pi*sigma^4)).*exp(-(x.^2+y.^2)/(2*sigma^2));
    case 'y'
        DGauss=-(y./(2*pi*sigma^4)).*exp(-(x.^2+y.^2)/(2*sigma^2));
    case 'xx'
        DGauss = 1/(2*pi*sigma^4) * (x.^2/sigma^2 - 1) .* exp(-(x.^2 + y.^2)/(2*sigma^2));
    case {'xy','yx'}
        DGauss = 1/(2*pi*sigma^6) * (x .* y)           .* exp(-(x.^2 + y.^2)/(2*sigma^2));
    case 'yy'
        DGauss = 1/(2*pi*sigma^4) * (y.^2/sigma^2 - 1) .* exp(-(x.^2 + y.^2)/(2*sigma^2));
end

%J = imfilter(I,DGauss,'conv','symmetric');
J = imfilter(I,DGauss,'corr');
