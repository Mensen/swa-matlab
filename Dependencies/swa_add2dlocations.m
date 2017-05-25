%% Add 2D coordinates to electrode file...
function eloc = swa_add2dlocations(eloc, GS)

if nargin < 2
   GS = 40; 
end

% check the theta coordinates exist
if ~isfield(eloc, 'theta')
    error('Could not find a "theta" field in the eloc structure');
end

Th = pi/180*[eloc.theta];      % Calculate theta values from x,y,z e_loc
Rd = [eloc.radius];              % Calculate radian values from x,y,z e_loc

x = Rd.*cos(Th);                                      % Calculate 2D projected X
y = Rd.*sin(Th);                                      % Calculate 2D projected Y

x = x(:);
x = x-min(x); 
x = num2cell(((x/max(x))*(GS-1))+1);

y = y(:);
y = y-min(y); 
y = num2cell(((y/max(y))*(GS-1))+1);

[eloc.x] = deal(x{:});
[eloc.y] = deal(y{:});