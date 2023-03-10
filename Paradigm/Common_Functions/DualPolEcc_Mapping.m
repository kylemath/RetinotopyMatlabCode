function DualPolEcc_Mapping(Parameters, Emulate, SaveAps)
%DualPolEcc_Mapping(Parameters, Emulate, SaveAps)
%
% Runs a dual polar & eccentricity mapping.
% If SaveAps is true it saves the aperture mask for each volume (for pRF).
%

if nargin < 3
    SaveAps = false;
end

%% Fixed parameter to ensure things work
Cycles_per_Expmt = [6 10 4 5] * Parameters.Repetitions;  % Number of cycles for polar & eccentricity & their blanks
Volumes_per_Cycle = [20 12 30 24];  % Duration of each cycle (polar, eccentricity, blanks) in volumes
Wedges = repmat(1:Volumes_per_Cycle(1), 1, Cycles_per_Expmt(1))';
Rings = repmat(1:Volumes_per_Cycle(2), 1, Cycles_per_Expmt(2))';
% Whether blanks are included or not
if Parameters.Blanks
    WedgeVisible = ~(repmat((1:Volumes_per_Cycle(3))', Cycles_per_Expmt(3), 1) > Volumes_per_Cycle(1)/2);
    RingVisible = ~(repmat((1:Volumes_per_Cycle(4))', Cycles_per_Expmt(4), 1) > Volumes_per_Cycle(2)/2 ...
                        & repmat((1:Volumes_per_Cycle(4))', Cycles_per_Expmt(4), 1) < Volumes_per_Cycle(4)-Volumes_per_Cycle(2)/2+1);
else
    WedgeVisible = ones(length(Wedges),1);
    RingVisible = ones(length(Rings),1);
end
% Direction of cycling
if Parameters.Direction == '-'
    Wedges = flipud(Wedges);
    Rings = flipud(Rings);
end

% Default is without scanner!
if nargin < 2
    Emulate = 1;
end

% Create the mandatory folders if not already present 
if ~exist([cd filesep 'Results'], 'dir')
    mkdir('Results');
end

%% Initialize randomness & keycodes
SetupRand;
SetupKeyCodes;

%% Behavioural data
Behaviour = struct;
Behaviour.EventTime = [];
Behaviour.Response = [];
Behaviour.ResponseTime = [];

%% Event timings 
Events = [];
for e = Parameters.TR : Parameters.Event_Duration : (Cycles_per_Expmt(1) * Volumes_per_Cycle(1) * Parameters.TR)
    if rand < Parameters.Prob_of_Event
        Events = [Events; e];
    end
end
% Add a dummy event at the end of the Universe
Events = [Events; Inf];

%% Configure scanner 
if Emulate 
    % Emulate scanner
    TrigStr = 'Press key to start...';    % Trigger string
else
    % Real scanner
    TrigStr = 'Stand by for scan...';    % Trigger string
end

%% Initialize PTB
[Win Rect] = Screen('OpenWindow', Parameters.Screen, Parameters.Background, Parameters.Resolution, 32); 
Screen('TextFont', Win, Parameters.FontName);
Screen('TextSize', Win, Parameters.FontSize);
Screen('BlendFunction', Win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
HideCursor;
RefreshDur = Screen('GetFlipInterval',Win);
Slack = RefreshDur / 2;

%% Various variables
Results = [];
CurrVolume = 0;
Slice_Duration = Parameters.TR / Parameters.Number_of_Slices;
Start_of_Expmt = NaN;

%% Initialization
% Spiderweb coordinates
[Ix Iy] = pol2cart([0:30:330]/180*pi, Parameters.Fixation_Width(1));
[Ox Oy] = pol2cart([0:30:330]/180*pi, Rect(3)/2);
Rc = Rect(3) - Parameters.Fixation_Width(2);
Sc = round(Rc / 10);
Wc = Parameters.Fixation_Width(2) : Sc : Rect(3);
Wa = round(Parameters.Spider_Web * 255);

% Load background movie
StimRect = [0 0 repmat(size(Parameters.Stimulus,1), 1, 2)];
BgdTextures = [];
if length(size(Parameters.Stimulus)) < 4
    for f = 1:size(Parameters.Stimulus, 3)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,f));
    end
else
    for f = 1:size(Parameters.Stimulus, 4)
        BgdTextures(f) = Screen('MakeTexture', Win, Parameters.Stimulus(:,:,:,f));
    end
end

% Background variables
CurrFrame = 0;
CurrStim = 1;

% Advancement per volume
Angle_per_Vol = 360 / Volumes_per_Cycle(1);  % Angle steps per volume
Pixels_per_Vol = StimRect(3) / Volumes_per_Cycle(2);  % Steps in ring width per volume

% Initialize circular Aperture
CircAperture = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
if SaveAps
    ApFrm = zeros(100, 100, length(Wedges));
    SavWin = Screen('MakeTexture', Win, 127 * ones(Rect([4 3])));
end

% If scanning use Cogent
if Emulate == 0
    config_serial;
    start_cogent;
    Port = 1;
end

%% Standby screen
Screen('FillRect', Win, Parameters.Background, Rect);
DrawFormattedText(Win, [Parameters.Welcome '\n \n' Parameters.Instruction '\n \n' TrigStr], 'center', 'center', Parameters.Foreground); 
Screen('Flip', Win);
if Emulate
    WaitSecs(0.1);
    KbWait;
    [bkp Start_of_Expmt bk] = KbCheck;           
else
    %%% CHANGE THIS TO WHATEVER CODE YOU USE TO TRIGGER YOUR SCRIPT!!! %%%
    CurrSlice = waitslice(Port, 1);  
    bk = zeros(1,256);
end

% Abort if Escape was pressed
if bk(KeyCodes.Escape) 
    % Abort screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, 'Experiment was aborted!', 'center', 'center', Parameters.Foreground); 
    Screen('Flip', Win);
    WaitSecs(0.5);
    ShowCursor;
    Screen('CloseAll');
    new_line;
    disp('Experiment aborted by user!'); 
    new_line;
    % Experiment duration
    End_of_Expmt = GetSecs;
    new_line;
    ExpmtDur = End_of_Expmt - Start_of_Expmt;
    ExpmtDurMin = floor(ExpmtDur/60);
    ExpmtDurSec = mod(ExpmtDur, 60);
    disp(['Experiment lasted ' n2s(ExpmtDurMin) ' minutes, ' n2s(ExpmtDurSec) ' seconds']);
    new_line;
    return;
end
Screen('FillRect', Win, Parameters.Background, Rect);
Screen('Flip', Win);

% Dummy volumes
Screen('FillRect', CircAperture, [127 127 127]);    
% Overlay spiderweb
if Wa > 0
    for s = 1:length(Ix)
        Screen('DrawLines', Win, [[Ix(s);Iy(s)] [Ox(s);Oy(s)]], 1, [0 0 0 Wa], Rect(3:4)/2);
    end
    for s = Wc
        Screen('FrameOval', Win, [0 0 0 Wa], CenterRect([0 0 s s], Rect));
    end
end
% Draw fixation dot
Screen('FillOval', Win, [0 0 127], CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));
Screen('Flip', Win);
WaitSecs(Parameters.Dummies * Parameters.TR);
Start_of_Expmt = GetSecs;

% Behaviour structure
Behaviour.EventTime = Events;
k = 0;  % Toggle this when key was pressed recently

% Begin trial
TrialOutput = struct;
TrialOutput.TrialOnset = GetSecs;
TrialOutput.TrialOffset = NaN;

%% Stimulus movie
CurrVolume = 1;
while CurrVolume <= length(Wedges)
    % Determine current frame 
    CurrFrame = CurrFrame + 1;
    if CurrFrame > Parameters.Refreshs_per_Stim 
        CurrFrame = 1;
        CurrStim = CurrStim + 1;
    end
    if CurrStim > size(Parameters.Stimulus, length(size(Parameters.Stimulus)))
        CurrStim = 1;
    end

    % Create Aperture
    Screen('FillRect', CircAperture, [127 127 127]);
    CurrWidth = Rings(CurrVolume) * Pixels_per_Vol;
    if RingVisible(CurrVolume) 
        Screen('FillOval', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(CurrWidth,1,2)], Rect));
        Screen('FillOval', CircAperture, [Parameters.Background 255], CenterRect([0 0 repmat(CurrWidth - Pixels_per_Vol + 1,1,2)], Rect));
    end
    CurrAngle = Wedges(CurrVolume) * Angle_per_Vol - Angle_per_Vol * 1.5 + 90;
    if WedgeVisible(CurrVolume)
        Screen('FillArc', CircAperture, [0 0 0 0], CenterRect([0 0 repmat(StimRect(4),1,2)], Rect), CurrAngle, Angle_per_Vol);
    end
    % Rotate background movie?
    BgdAngle = cos((GetSecs-TrialOutput.TrialOnset)/Parameters.TR * 2*pi) * Parameters.Sine_Rotation;

    % Draw movie frame
    Screen('DrawTexture', Win, BgdTextures(CurrStim), StimRect, CenterRect(StimRect, Rect), BgdAngle+CurrAngle);
    % Draw aperture
    Screen('DrawTexture', Win, CircAperture, Rect, Rect);
    CurrEvents = Events - (GetSecs - Start_of_Expmt);
    % Draw hole around fixation
    SmoothOval(Win, Parameters.Background, CenterRect([0 0 Parameters.Fixation_Width(2) Parameters.Fixation_Width(2)], Rect), Parameters.Fringe);    

    % If saving movie
    if SaveAps == 1 && PrevVolume ~= CurrVolume
        PrevVolume = CurrVolume;
        CurApImg = Screen('GetImage', Win, CenterRect(StimRect, Rect), 'backBuffer'); 
        CurApImg = rgb2gray(CurApImg);
        CurApImg = abs(double(CurApImg)-127)/127;
        ApFrm(:,:,Parameters.Volumes_per_Trial*(Trial-1)+CurrVolume) = imresize(CurApImg, [100 100]);
    elseif SaveAps == 2
        CurApImg = Screen('GetImage', Win, CenterRect(StimRect, Rect), 'backBuffer'); 
        CurApImg = rgb2gray(CurApImg);
        sf = sf + 1;
        ApFrm(:,:,sf) = imresize(CurApImg, [300 300]);
    end

    % Draw fixation dot 
    if sum(CurrEvents > 0 & CurrEvents < Parameters.Event_Duration)
        % This is an event
        Screen('FillOval', Win, [127 0 127], CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));    
    else
        % This is not an event
        Screen('FillOval', Win, [0 0 127], CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));    
    end
    % Check whether the refractory period of key press has passed
    if k ~= 0 && GetSecs-KeyTime >= 2*Parameters.Event_Duration
        k = 0;
    end
    
    % Overlay spiderweb
    if Wa > 0
        for s = 1:length(Ix)
            Screen('DrawLines', Win, [[Ix(s);Iy(s)] [Ox(s);Oy(s)]], 1, [0 0 0 Wa], Rect(3:4)/2);
        end
        for s = Wc
            Screen('FrameOval', Win, [0 0 0 Wa], CenterRect([0 0 s s], Rect));
        end
    end
    % Flip screen
    Screen('Flip', Win);

    % Behavioural response
    if k == 0
        [Keypr KeyTime Key] = KbCheck;
        if Keypr 
            k = 1;
            Behaviour.Response = [Behaviour.Response; find(Key)];
            Behaviour.ResponseTime = [Behaviour.ResponseTime; KeyTime - Start_of_Expmt];
        end
    end
    TrialOutput.Key = Key;
    % Abort if Escape was pressed
    if find(TrialOutput.Key) == KeyCodes.Escape
        % Abort screen
        Screen('FillRect', Win, Parameters.Background, Rect);
        DrawFormattedText(Win, 'Experiment was aborted mid-experiment!', 'center', 'center', Parameters.Foreground); 
        WaitSecs(0.5);
        ShowCursor;
        Screen('CloseAll');
        new_line; 
        disp('Experiment aborted by user mid-experiment!'); 
        new_line;
        % Experiment duration
        End_of_Expmt = GetSecs;
        new_line;
        ExpmtDur = End_of_Expmt - Start_of_Expmt;
        ExpmtDurMin = floor(ExpmtDur/60);
        ExpmtDurSec = mod(ExpmtDur, 60);
        disp(['Experiment lasted ' n2s(ExpmtDurMin) ' minutes, ' n2s(ExpmtDurSec) ' seconds']);
        new_line;
        return;
    end

    % Determine current volume
    CurrVolume = floor((GetSecs - Start_of_Expmt) / Parameters.TR) + 1;
end

% Trial end time
TrialOutput.TrialOffset = GetSecs;

% Record trial results   
Results = [Results; TrialOutput];

% Clock after experiment
End_of_Expmt = GetSecs;

%% Save results
Parameters = rmfield(Parameters, 'Stimulus');  % Remove stimulus from data
Screen('FillRect', Win, Parameters.Background, Rect);
DrawFormattedText(Win, 'Saving data...', 'center', 'center', Parameters.Foreground); 
Screen('Flip', Win);
save(['Results' filesep Parameters.Session_name]);

%%% REMOVE THIS IF YOU DON'T USE COGENT!!! %%%
% Turn off Cogent
if Emulate == 0
    stop_cogent;
end

%% Farewell screen
Screen('FillRect', Win, Parameters.Background, Rect);
DrawFormattedText(Win, 'Thank you!', 'center', 'center', Parameters.Foreground); 
Screen('Flip', Win);
WaitSecs(Parameters.TR * Parameters.Overrun);
ShowCursor;
Screen('CloseAll');

%% Experiment duration
new_line;
ExpmtDur = End_of_Expmt - Start_of_Expmt;
ExpmtDurMin = floor(ExpmtDur/60);
ExpmtDurSec = mod(ExpmtDur, 60);
disp(['Experiment lasted ' n2s(ExpmtDurMin) ' minutes, ' n2s(ExpmtDurSec) ' seconds']);
new_line;

%% Save apertures
if SaveAps
    save('Dual_Apertures', 'ApFrm');
end
