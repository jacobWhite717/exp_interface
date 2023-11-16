sca;
close all;
clear;

%% PTB setup    
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
screens = Screen('Screens'); 
screenNumber = max(screens);

white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;
blue_grey = [40 44 52]/255;
light_grey = [230 230 230]/255;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, blue_grey, []);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
border_size = 100;
full_boundary_box = [border_size, border_size, screenXpixels-border_size, screenYpixels-border_size];
half1_boundary_box = [border_size, border_size, xCenter-(border_size/2), screenYpixels-border_size];
half2_boundary_box = [xCenter+(border_size/2), border_size, screenXpixels-border_size, screenYpixels-border_size];

% make splash textures
img_read_location = 'resources/img/read_splash.png';
img_read = imread(img_read_location);
texture_read = Screen('MakeTexture', window, img_read);

img_rest_location = 'resources/img/rest_splash.png';
img_rest = imread(img_rest_location);
texture_rest = Screen('MakeTexture', window, img_rest);

img_listen_location = 'resources/img/listen_splash.png';
img_listen = imread(img_listen_location);
texture_listen = Screen('MakeTexture', window, img_listen);

% window text setup
text_size = 36;
wrap_num = floor((full_boundary_box(3)-full_boundary_box(1))/text_size * 2.2);
Screen('TextSize', window, text_size);
Screen('TextFont', window, 'Lato');

% cross drawing setup
fixCrossDimPix = 40;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
lineWidthPix = 4;


%% audio setup
InitializePsychSound(1);
nrchannels = 1;
sampling_rate = 22050;
volume = 0.5;

pahandle = PsychPortAudio('Open', 2   , 1, 1, sampling_rate, nrchannels);
PsychPortAudio('Volume', pahandle, volume);


%% Triggerbox / Serial I/O setup
% serial_port = 'COM3';  % CHANGE TO APPROPRIATE PORT
% baud_rate = 115200;
% inter_trigger_interval = 0.005;
% tbox = SerialTrigger(serial_port, baud_rate, inter_trigger_interval);


%% TRIAL PARAMETERS
transition_time = 1;
rest_time = 1;
trigger_buffer_dur = 0;

block_count = 1;


%% tasks
task_num = 1;
trial_dur = 5;
text_set = return_text_set(trial_dur);

num_trials_block = 3;
num_trials = 3;

num_blocks = 1;

full_trial_order = [1];%; 2; 0];

text_order = [2];
reading_counter = 1;

audio_order = [3];
listening_counter = 1;

% instuction spalsh screen at start of task
instructions_loc = sprintf('resources/img/%is_instructions.png', trial_dur);
% instructions_loc = sprintf('resources/img/5s_instructions.png');
img_instruct = imread(instructions_loc);
texture_instruct = Screen('MakeTexture', window, img_instruct);
Screen('DrawTexture', window, texture_instruct, [], [], 0);
Screen('Flip', window);
KbWait([], 3, inf); 

for i = 1:num_trials
    reading_flag = full_trial_order(i) == 1;
    listening_flag = full_trial_order(i) == 2;
    rest_flag = full_trial_order(i) == 0;

    %% start of queue
    if reading_flag
        Screen('DrawTexture', window, texture_read, [], [], 0);
    elseif listening_flag
        Screen('DrawTexture', window, texture_listen, [], [], 0);
    else
        Screen('DrawTexture', window, texture_rest, [], [], 0);
    end
    trial_counter_str = sprintf("Task %i / Trial %i", task_num, i);
    Screen('DrawText', window, char(trial_counter_str), 100, 100, light_grey);
    Screen('Flip', window);
    KbWait([], 3, inf);  

    %% start of queue -> text transition
    Screen('FillRect', window, blue_grey);
    Screen('Flip', window);
    WaitSecs(transition_time);
    
    %% start of text
    if reading_flag
        str_num = text_order(reading_counter);
        reading_counter = reading_counter + 1;
        cur_text = char(text_set(str_num));
        DrawFormattedText(window, cur_text, 'wrapat', 'center', light_grey, wrap_num, 0, 0, 1.5, 0, full_boundary_box);
    elseif listening_flag
        audio_num = audio_order(listening_counter);
        listening_counter = listening_counter+ 1;
        audio_file = sprintf("resources/audio/%i/%i.mp3", trial_dur, audio_num);
        [audio_vals, ~] = audioread(audio_file);
        PsychPortAudio('FillBuffer', pahandle, audio_vals');
        Screen('DrawLines', window, allCoords, lineWidthPix, light_grey, [xCenter yCenter], 2);
    else
        Screen('DrawLines', window, allCoords, lineWidthPix, light_grey, [xCenter yCenter], 2);
    end
    
    t_start = tic;
    Screen('Flip', window);
%     if listening_flag
%         PsychPortAudio('Start', pahandle, 1, 0, 1);
%     end

%     if reading_flag
%         tbox.trigger(1);
%     elseif listening_flag
%         tbox.trigger(6);
%     else
%         tbox.trigger(2);
%     end

    WaitSecs(trial_dur); 
    
%     if listening_flag
%         PsychPortAudio('Stop', pahandle);
%     end
    t_latency = toc(t_start);

    WaitSecs(trial_dur+1-t_latency);

%     tbox.trigger(5);
    

    %% start of rest 
%     Screen('FillRect', window, blue_grey);
%     Screen('Flip', window);
    WaitSecs(rest_time);


    %% end of block splash
    if mod(i, num_trials_block) == 0
        end_of_block_text = char(sprintf("End of block %i/%i\n\nPlease inform the facilitator that the block has been completed before continuing.\n\nPress any key to continue", block_count, num_blocks*3));
        block_count = block_count + 1;
        DrawFormattedText(window, end_of_block_text,...
                'center', 'center', light_grey, 100, 0, 0, 1.5, 0, full_boundary_box); 
        Screen('Flip', window);
        KbWait([], 3, inf);
    end
end


%% closing code
% tbox.disconnect();
PsychPortAudio('Close', pahandle);
sca;


%% helper functions 
function text = return_text_set(duration)
    if duration == 5 
        text = load("resources/text/text_5s.mat").text_5s;
    elseif duration == 15 
        text = load("resources/text/text_15s.mat").text_15s;
    elseif duration == 30 
        text = load("resources/text/text_30s.mat").text_30s;
    elseif duration == 60 
        text = load("resources/text/text_60s.mat").text_60s;
    end
end


% block trial index (bti) math
function index = bti(block_size, block, trial)
    index = block_size*(block - 1) + trial;
end

