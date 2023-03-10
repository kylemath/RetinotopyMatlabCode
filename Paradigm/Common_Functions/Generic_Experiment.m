function Generic_Experiment(Parameters, Emulate)
%Generic_Experiment(Parameters, Emulate)
%
% Runs a generic psychophysics experiment. Originally this was conceived 
% for the method of constant stimuli, but it may also adapted for the
% use of staircase procedures. It should also be usable in the scanner.
%

% Default is without scanner!
if nargin < 2
    Emulate = 1;
end

% Create the mandatory folders if not already present 
if ~exist([cd filesep 'Results'], 'dir')
    mkdir('Results');
end

% Check if eyetracker defined
if ~isfield(Parameters, 'Eye_tracker')
    Parameters.Eye_tracker = false;
end

%% Initialize randomness & keycodes
SetupRand;
SetupKeyCodes;

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

%% If desired, initialize eyetracker 
if Parameters.Eye_tracker
    if Eyelink('Initialize') ~= 0	
        error('Problem initialising the eyetracker!'); 
    end
    Eye_params = EyelinkInitDefaults(Win);
    Eyelink('Openfile', 'Test.edf');  % Open a file on the eyetracker
    Eyelink('StartRecording');  % Start recording to the file
    Eye_error = Eyelink('CheckRecording');
    if Eyelink('NewFloatSampleAvailable') > 0
        Eye_used = Eyelink('EyeAvailable'); % Get eye that's tracked
        if Eye_used == Eye_params.BINOCULAR; 
            % If both eyes are tracked use left
            Eye_used = Eye_params.LEFT_EYE;         
        end
    end
end

%% Various variables
Results = [];
CurrVolume = 0;
Start_of_Expmt = NaN;

% Custom initialization
if exist('Initialization.m') == 2
    Initialization;
end

%% Start Cogent
%%% CHANGE THIS TO WHATEVER CODE YOU USE TO TRIGGER YOUR SCRIPT!!! %%%
% If scanning use Cogent
if Emulate == 0
    config_serial;
    start_cogent;
    Port = 1;
end

%% Loop through blocks
for Block = 0 : Parameters.Blocks_per_Expmt-1
    if Parameters.Shuffle_Conditions
        %% Reshuffle the conditions for this block
        Reshuffling = randperm(length(Parameters.Conditions));
    else
        %% Conditions in pre-defined order
        Reshuffling = 1 : length(Parameters.Conditions);
    end
    
    %% Standby screen
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, [Parameters.Welcome '\n \n' Parameters.Instruction '\n \n' ... 
                                            'Block ' num2str(Block+1) ' of ' num2str(Parameters.Blocks_per_Expmt) '\n \n' ...
                                            TrigStr], 'center', 'center', Parameters.Foreground); 
    Screen('Flip', Win);
    if Emulate
        WaitSecs(0.1);
        KbWait;
        [bkp bkt bk] = KbCheck;           
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
        %%% REMOVE THIS IF YOU DON'T USE COGENT!!! %%%
        if Emulate == 0
        % Turn off Cogent
            stop_cogent;
        end
        % Shutdown eye tracker if used
        if Parameters.Eye_tracker
            Eyelink('StopRecording');
            Eyelink('CloseFile');
            Eyelink('ShutDown');
        end
        return;
    end
    Screen('FillRect', Win, Parameters.Background, Rect);
    Screen('Flip', Win);

    %% Dummy volumes
    if isfield(Parameters, 'Fixation_Width')
        Screen('FillRect', Win, Parameters.Background);    
        Screen('FillOval', Win, Parameters.Foreground, CenterRect([0 0 Parameters.Fixation_Width(1) Parameters.Fixation_Width(1)], Rect));    
        Screen('Flip', Win);
    end
    WaitSecs(Parameters.Dummies * Parameters.TR);
    Start_of_Block(Block+1) = GetSecs;
    if isnan(Start_of_Expmt)
        Start_of_Expmt = Start_of_Block(Block+1);
    end

    %% Run stimulus sequence 
    for Trial = 1 : length(Parameters.Conditions)    
    	% Current volume 
    	CurrVolume = ceil((GetSecs - Start_of_Block(Block+1)) / Parameters.TR);
        
        % Begin trial
        TrialOutput = struct;
        TrialOutput.TrialOnset = GetSecs;
        TrialOutput.TrialOffset = NaN;
        if Parameters.Eye_tracker
            TrialOutput.Eye = [];
        end

        % Call stimulation sequence
        CurrCondit = Parameters.Conditions(Reshuffling(Trial));
        eval(Parameters.Stimulus_Sequence);  % Custom script for each experiment!
              
        % Abort if Escape was pressed
        if find(TrialOutput.Key) == KeyCodes.Escape
            % Abort screen
            Screen('FillRect', Win, Parameters.Background, Rect);
            DrawFormattedText(Win, 'Experiment was aborted mid-block!', 'center', 'center', Parameters.Foreground); 
            WaitSecs(0.5);
            ShowCursor;
            Screen('CloseAll');
            new_line; 
            disp('Experiment aborted by user mid-block!'); 
            new_line;
            % Experiment duration
            End_of_Expmt = GetSecs;
            new_line;
            ExpmtDur = End_of_Expmt - Start_of_Expmt;
            ExpmtDurMin = floor(ExpmtDur/60);
            ExpmtDurSec = mod(ExpmtDur, 60);
            disp(['Experiment lasted ' n2s(ExpmtDurMin) ' minutes, ' n2s(ExpmtDurSec) ' seconds']);
            new_line;
            %%% REMOVE THIS IF YOU DON'T USE COGENT!!! %%%
            if Emulate == 0
            % Turn off Cogent
                stop_cogent;
            end
            % Shutdown eye tracker if used
            if Parameters.Eye_tracker
                Eyelink('StopRecording');
                Eyelink('CloseFile');
                Eyelink('ShutDown');
            end
            return;
        end
        
        % Reaction to response
        if exist('.\Feedback.m') == 2
            Feedback;
        end
        TrialOutput.TrialOffset = GetSecs;
        
        % Record trial results   
        Results = [Results; TrialOutput];
    end
    
    % Clock after experiment
    End_of_Expmt = GetSecs;

    %% Save results of current block
    Screen('FillRect', Win, Parameters.Background, Rect);
    DrawFormattedText(Win, 'Saving data...', 'center', 'center', Parameters.Foreground); 
    Screen('Flip', Win);
    save(['Results' filesep Parameters.Session_name]);
end

%% Shut down Cogent
%%% REMOVE THIS IF YOU DON'T USE COGENT!!! %%%
if Emulate == 0
% Turn off Cogent
    stop_cogent;
end

%% Shutdown eye tracker if used
if Parameters.Eye_tracker
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    Eyelink('ShutDown');
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

