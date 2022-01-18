%% Create foreground detector object
detector = vision.ForegroundDetector("NumTrainingFrames", 20,...
                                     "InitialVariance", 60*60,...
                                     "MinimumBackgroundRatio", 0.7,...
                                     "NumGaussians", 3);

%% Read in video file
filename = "miniv.webm";
videoObject = VideoReader(filename);
reader = vision.VideoFileReader(filename,...
                                "VideoOutputDataType", "uint8");

%% Create object for blob analysis
blob = vision.BlobAnalysis("MinimumBlobArea", 100);

%% Set up video player
player = vision.VideoPlayer("Position", [180, 100, 700, 400]);
player2 = vision.VideoPlayer("Position", [300, 200, 700, 400]);

%% video writing
mywriter = VideoWriter("mymovie.avi");
open(mywriter);

%% creating a document in txt formate
fileid = fopen("details.txt","w");

%% Mail ID
% mailID = "Mail.com"; %write mail id to whome u want to send mail in place of --MailId--
% mailSender();

%% initialize the variables
NoFramObjDet = 0;
NoFrameObjNotDet=0;
MotionState = 0; %0 means motion not taking place, 1 means motion taking place
frameNo = 0;
motionDet = false; %false means motion has stoped, thus stop writing video 
                   %True means motion is taking place, thus keep writing video
NthMotionDet = 0;
StopWriting = false; %false stop writing video %True keep writing video
hr = 0;
min = 0;
sec = 0;

%% Foreground detection
%create loop to run through video
while ~isDone(reader)
    
    frameNo = frameNo +1;      %counting frames
    frame = step(reader); %load next frame
  
    %create foreground mask 
    mask = detector.step(frame);
    mask = imopen(mask, strel("rectangle", [3,3]));
    mask = imclose(mask, strel("rectangle", [15, 15]));
    mask = imfill(mask, "holes");
    
    %find bounding box
    [~,~,bbox] = blob.step(mask);
    %to indicate if object is detected or not
    ObjDetCount = size(bbox,1);
    
    %checking if there is any motion
    if(ObjDetCount>0)
        NoFramObjDet = NoFramObjDet+1; %used to count the no of frames the motion is detected to consider it as moving object
        if(NoFramObjDet >= 20) %True of object is detected in more than 5 frames
            if((ObjDetCount>0)&&(MotionState==0))
                
                %intemating the detection to the owner
                if (NthMotionDet == 0)
                    messageString = strcat("Hello Raja," + newline + "Wish You Many More Happy Returns Of the Day Raja." + newline +...
                                           "Hope you are doing well see you soon."+ newline + "Take care" + newline + "Thankyou" + newline + "HR");
                    %change --Happy-birthday.jpg-- image to the image that 
                    %you want to send 
%                     sendmail(mailID,"May More happy returns of Day RAJA: From HR",messageString,{'Happy-birthday.jpg'}) 
                end
                
                NoFramObjDet = 0; %setting no of frames object detected to 0
                MotionState=1; %to indicate that motion has begin (if 0 motion was not there till then/ if 1 motion was there till then)
                motionDet = true; %used to write video when it is true
                StartingTime = clock; %reads the starting time of motion in matrix form
                if(StartingTime(4)>12) % if hours in PM set it to IST 
                   StartingHr = StartingTime(4)-12; 
                else
                   StartingHr = StartingTime(4); 
                end
                %location of where motion is detected
                SLocation = "Location: Home" + newline;
                %Starting time in straing
                SStartTime = newline + "Started" + newline + "  Date: " + int2str(StartingTime(3)) + "/" + int2str(StartingTime(2)) + "/" + int2str(StartingTime(1)) + newline + .... 
                     "  Time: " + int2str(StartingHr) + ":" + int2str(StartingTime(5)) + ":" + int2str(StartingTime(6)) + newline;
                %Frame no of motion detected.
                SStartFrameNo = "  Starting Frame No: " + int2str(frameNo) + newline;
                %The frame pic in which the motion was detected first
                figure(1)
                imshow(frame)
            end
        end
    end
    
    %checking if there is no motion
    if(ObjDetCount==0)
        NoFrameObjNotDet = NoFrameObjNotDet+1; %used to count the no of frames the motion is not detected to consider that there is no motion
        if(NoFrameObjNotDet >= 5)
            if((ObjDetCount == 0)&&(MotionState==1))
                NoFrameObjNotDet=0;
                MotionState=0; %to indicate that motion has begin (if 0 motion was not there till then/ if 1 motion was there till then)
                motionDet = false; %reads the ending time of motion
                EndTime = clock;
                if(EndTime(4)>12) 
                   ehr = StartingTime(4)-12; 
                else
                    ehr = StartingTime(4); 
                end
                SEndTime = newline + "Ended" + newline + "  Date: " + int2str(EndTime(3)) + "/" + int2str(EndTime(2)) + "/" + int2str(EndTime(1)) + newline + .... 
                     "  Time: " + int2str(ehr) + ":" + int2str(EndTime(5)) + ":" + int2str(EndTime(6)) + newline;
                SEndFrameNo = "  Starting Frame No: " + int2str(frameNo) + newline;
                %%The frame pic in which the motion stopped detected
                figure(2)
                imshow(frame)
                StopWriting = true;
            end
        end
    end
    
    %writing the video where the motion is detected
    if(motionDet)
        %insert bounding box in frame
        ObjFrame = insertShape(frame,"rectangle",bbox,"color","r");
        %writing video
        writeVideo(mywriter,im2double(ObjFrame));
    end 
    %inserting empty frames to indecate the ending of the video
    if(~motionDet && StopWriting)
        for i=1:30
             writeVideo(mywriter, zeros(videoObject.Height,videoObject.Width));
        end
    end
    
    % duration of motion
    if(~motionDet && StopWriting)
        %documentation of detections
        NthMotionDet = NthMotionDet+1;
        hr = abs(EndTime(4)-StartingTime(4));
        min = abs(EndTime(5)-StartingTime(5));
        sec = abs(EndTime(6)-StartingTime(6));
        SMotionDuration = newline + "Duration of motion(" + int2str(NthMotionDet) + "): " + int2str(hr) + ":" + int2str(min) + ":" + int2str(sec) + newline;

        final = strcat(SLocation + SStartTime + SStartFrameNo + SEndTime + SEndFrameNo + SMotionDuration);

        fprintf(fileid,"%s", newline ,final);
        
%         sending mail with details
%         sendmail(mailID,"Details of the detected Motion",final)
        
        hr = 0;
        min = 0;
        sec = 0;
        StopWriting = false;
        DetailsMail = true;
    end

    %update video player  
    player.step(frame);
    player2.step(mask);
end
%% sending the details of the detection after processing in encrypted form
EncryptMess();
%change --WishVM.jpg-- image with your encrypted image 
% sendmail(mailID,"May More happy returns of Day: New Horizon College of Engineering",'HAPPY BIRTHDAY Raja',{'WishVM.jpg'});


%% %% Clean up
fclose(fileid);
close(mywriter);
release(detector);
release(reader);
release(blob);
release(player);
release(player2);
%% mail control
% function mailSender()
% smailID = "Mail.com"; %write mail id to whome u want to send mail in place of --MailId--
% setpref("Internet","SMTP_Username",smailID);
% setpref("Internet","SMTP_Password","Password"); %write the mail id account password in place of --WriteYouMailIdPassword--
% setpref("Internet","E_mail",smailID);
% setpref("Internet","SMTP_Server","smtp.gmail.com");
% props = java.lang.System.getProperties;
% props.setProperty("mail.smtp.auth","true");
% props.setProperty( "mail.smtp.starttls.enable", "true" );
% props.setProperty("mail.smtp.socketFactory.class",...
%                    "javax.net.ssl.SSLSocketFactory");
% props.setProperty( "mail.smtp.socketFactory.port", "465" );
% 
% end

%% encript
function EncryptMess()

candidate_Image=imread('someone.jpg'); %To load the image
DocWithMess = 'details.txt';
secret=fopen(DocWithMess,'rb');         %To open the secret file
[DocWithMess,L]=fread(secret,'ubit1');       %To read secret file as bin array
length(DocWithMess);
% L is the length of the secret file
[n,m]=size(candidate_Image); % n= width, m=height*3
m=m/3;
%m*n is the max size to save the data
if (m*n*3<L)
    msg=msgbox('your picture is too small', 'size error', 'error', 'modal');
    pause (1);
    if (ishandle(msg))
        close(msg);
    end
end
latest_data=candidate_Image;
count=1;

for i=1:m  % width
    for j=1:n  % height
        for k=1:3  %RGB
            latest_data (i, j, k)=candidate_Image (i, j, k)-mod (candidate_Image (i,j,k), 2) +DocWithMess (count, 1);
            if count==L
                break;
            end
            count=count+1;
        end
        if count==L
            break;
        end
    end
    if (L==count)
        break;
    end
end
%change --WishVM.jpg-- to the name by which you want to save your encripted
%image
imwrite (latest_data, 'WishVM.jpg', 'bmp');

CC=DocWithMess;
count1=1;
for i=1:m
    for j=1:n
        for k=1:3
            CC (count1) =latest_data (i, j, k)-candidate_Image (i, j, k);
            if count1==L
                break
            end
            count1= count1+1;
        end
        if count1==L
            break
        end
    end
    if count1==L
        break
    end
end

end

