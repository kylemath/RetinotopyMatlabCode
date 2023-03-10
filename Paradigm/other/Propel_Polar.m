function Propel_Polar(Subj, Direc, Stim, Emul)
%Propel_Polar(Subj, Direc, Stim, Emul)
%
% Polar mapping with bi-field wedge
%   Subj :  String with subject ID
%   Direc : '+' or '-' for clockwise/expanding or anticlockwise/contracting
%   Stim :  Stimulus file name e.g. 'Checkerboard'
%   Emul :  0 = Triggered by scanner, 1 = Trigger by keypress
%

if nargin == 0
    Subj = 'Demo';
    Direc = '+';
    Stim = 'Checkerboard';
    Emul = 1;
end
addpath('Common_Functions');
Parameters = struct;    % Initialize the parameters variable

%% Engine parameters
Parameters.Screen=0;    % Main screen
Parameters.Resolution=[0 0 1024 768];   % Resolution
Parameters.Foreground=[0 0 0];  % Foreground colour
Parameters.Background=[127 127 127];    % Background colour
Parameters.FontSize = 20;   % Size of font
Parameters.FontName = 'Comic Sans MS';  % Font to use

%% Scanner parameters
Parameters.TR=3.06;   % Seconds per volume
Parameters.Number_of_Slices=36; % Number of slices
Parameters.Dummies=4;   % Dummy volumes
Parameters.Overrun=0;   % Dummy volumes at end

%% Experiment parameters
Parameters.Cycles_per_Expmt=10;  % Stimulus cycles per run
Parameters.Vols_per_Cycle=10;   % Volumes per cycle 
Parameters.Prob_of_Event=0.05;  % Probability of a target event
Parameters.Event_Duration=0.2;  % Duration of a target event
Parameters.Event_Size=30;  % Width of target circle
Parameters.Apperture='Propeller';   % Stimulus type
Parameters.Apperture_Width=40;  % Width of wedge in degrees
Parameters.Direction=Direc; % Direction of cycling
Parameters.Rotate_Stimulus=true;    % Does image rotate?
% Load stimulus movie
load(Stim);
Parameters.Stimulus=Stimulus;
Parameters.Rotate_Stimulus=true;   % Image rotates
Parameters.Refreshs_per_Stim=StimFrames;  % Video frames per stimulus frame
Parameters.Sine_Rotation=0;  % No rotation back & forth 

%% Various parameters
Parameters.Instruction='Please fixate at all times!\n\nPress button when a target appears!';
[Parameters.Session Parameters.Session_name]=CurrentSession([Subj '_' Stim '_Propel' Direc]); % Determine current session

%% Run the experiment
Retinotopic_Mapping(Parameters, Emul);
