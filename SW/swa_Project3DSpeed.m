% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% * Program: SW
% * Author: Anna Castelnovo & Matteo Zago
% * Created: 2017.09.21, 14:36
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function [twr, speed]  = swa_Project3DSpeed (Info, sw, scaleFactor, img)

if nargin < 4
   img = 1;
end

% assegna nome a variabili
% x, y ,z: coordinate elettrodi reali
% tw: coordinate travelling wave su griglia
% twr: coordinate travelling wave reali
y = [Info.Electrodes.X];
x = [Info.Electrodes.Y];
z = [Info.Electrodes.Z];

XYZ = [x', y', z'] * [scaleFactor 0 0; 0 scaleFactor 0; 0 0 scaleFactor];
x = XYZ(:,1);
y = XYZ(:,2);
z = XYZ(:,3);

% eloc = swa_add2dlocations(Info.Electrodes);

% estrae una travelling wave
tw = sw.Travelling_Streams{1}';

% trasformazione
a = min(x);
x1 = x - a;
b = max(x1);

c = min(y);
y1 = y - c;
d = max(y1);

twr(:,1) = (tw(:,1) * b)/(40-1) -1 + a;
twr(:,2) = (tw(:,2) * d)/(40-1) -1 + c;

% ricavo terza dimensione reale
F = scatteredInterpolant(x, y, z);
twr(:,3) = F(twr(:,1), twr(:,2));

% calcolo velocita (modulo vettore spostam diviso delay)
speed = sqrt(sum( twr.^2, 2)) ./ sw.Stream_Travelling_Delay ;

% grafico (opzionale)
if img
    suptitle('Botto');
    subplot(121);
    plot3(x,y,z,'*k'); hold on;
    speedRange = max(speed) - min(speed);
    speedColor = abs([speed-min(speed) zeros(size(speed)) zeros(size(speed))])./speedRange;
    for k = 1 : length(speed)
        twp = plot3(twr(k,1), twr(k,2), twr(k,3));
        set(twp, 'color', speedColor(k, :), 'marker', 'o');
    end
    title('3D real view');
    
    subplot(122);
    pcolor(sw.Travelling_DelayMap); hold on; grid on;
    plot([Info.Electrodes.x], [Info.Electrodes.y], '*k');
    for k = 1 : length(speed)
        twp = plot(tw(k,1), tw(k,2));
        set(twp, 'color', speedColor(k, :), 'marker', 'o');
    end
    colorbar;
    title('2D grid view');
end

%end
