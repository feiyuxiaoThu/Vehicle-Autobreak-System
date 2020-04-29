clear all
close all
%% physics enviroment construct
m=1462;%%total mass of a car
g=9.8;%%gravity acceleration
r=0.4;%% radius of wheel
m_w=35;%% mass of one wheel(including some axle mass and inertia)
iw=0.5*m_w*r*r;% estimate the rotation inertia for one wheel and axle
l=2.79;%% wheel base length
h=0.5;%%hight of car gravity center
%%here, the gravity center is in the middle of the wheel base, THUS
x1=1.565;
x2=l-x1;


%% initial condition
v0=70/3.6;%initial velocity
wv0=v0/r;%initial rotation angle velocity
nn=10^6;%interation times
tot_time=5;
dt=tot_time/nn;
dp=30000*dt;%%braking moment increase step
T=0.01;%%control period length

%%initialize the judgment of control logic
mm_f=zeros(nn,1);
nn_f=zeros(nn,1);
mm_r=zeros(nn,1);
nn_r=zeros(nn,1);

v=zeros(nn,1);
a=zeros(nn,1);
wa_f=zeros(nn,1);%% angle acceleration for front wheel
wa_r=zeros(nn,1);
wv_f=zeros(nn,1);
wv_r=zeros(nn,1);
p_f=zeros(nn,1);%% pressure to the ground for front wheel
p_r=zeros(nn,1);
bd_f=zeros(nn,1);%%braking drag TORQUE for front wheel
bd_r=zeros(nn,1);
gd_f=zeros(nn,1);%%ground drag FORCE for front wheel
gd_r=zeros(nn,1);
lmd_f=zeros(nn,1);%%slip rate for front wheel
lmd_r=zeros(nn,1);
miu_f=zeros(nn,1);
miu_r=zeros(nn,1);

%%here is for the best point storage
miu_f_max=0;
miu_r_max=0;%%maximum value of miu
lmd_f_best=0;
lmd_r_best=0;
wa_f_level=0;
wa_r_level=0;
level_f=0;
level_1_f=0;
level_2_f=0;
level_3_f=0;
level_r=0;
level_1_r=0;
level_2_r=0;
level_3_r=0;
in_out_f=0;
in_out_r=0;


t=zeros(nn,1);

%% initial value given
v(1)=v0;
wv_f(1)=wv0;
wv_r(1)=wv0;
p_f(1)=x2/(x1+x2)*m*g/2;
p_r(1)=x1/(x1+x2)*m*g/2;
%% interation process
for i=1:nn-1
    
    if v(i)<0
        break
    end
    
    t(i+1)=t(i)+dt;
    lmd_f(i+1)=100*(v(i)-r*wv_f(i))/v(i);
    lmd_r(i+1)=100*(v(i)-r*wv_r(i))/v(i);
    miu_f(i+1)=gd_f(i)/p_f(i);
    miu_r(i+1)=gd_r(i)/p_r(i);
    p_f(i+1)=m*g*((h*miu_r(i+1)+x2)/(h*miu_r(i+1)+x1+x2-h*miu_f(i+1)))/2;
    %%here we consider two wheels for front or rare direction
    p_r(i+1)=m*g*((-h*miu_f(i+1)+x1)/(h*miu_r(i+1)+x1+x2-h*miu_f(i+1)))/2;
    %%here is the magic function
    gd_f(i+1)=p_f(i+1)*magic_strange(lmd_f(i+1),p_f(i+1))*(rand(1)/20+1);
    gd_r(i+1)=p_r(i+1)*magic_low(lmd_r(i+1),p_r(i+1))*(rand(1)/20+1);
    
    if in_out_f==0
    if miu_f(i+1)>miu_f_max
        miu_f_max=miu_f(i+1);
        lmd_f_best=lmd_f(i+1);
        wa_f_level=abs(wa_f(i));
    end
    end
    if in_out_r==0
    if miu_r(i+1)>miu_r_max
        miu_r_max=miu_r(i+1);
        lmd_r_best=lmd_r(i+1);
        wa_r_level=abs(wa_r(i));
    end
    end
    
    
    if in_out_f==0
    [bd_f(i+1),mm_f(i+1),nn_f(i+1),in_out_f,level_1_f,level_2_f,level_3_f,level_f]=road_iden(bd_f(i),dt,nn_f(i),miu_f(i+1),miu_f_max,dp,T,lmd_f_best,wa_f_level);
    else
    [bd_f(i+1),mm_f(i+1),nn_f(i+1)]=modified_control(bd_f(i),wa_f(i),lmd_f(i+1),dt,mm_f(i),nn_f(i),level_1_f,level_2_f,level_3_f,level_f,dp,T);%%her is a simple braking function
    end
    
    if in_out_r==0
    [bd_r(i+1),mm_r(i+1),nn_r(i+1),in_out_r,level_1_r,level_2_r,level_3_r,level_r]=road_iden(bd_r(i),dt,nn_r(i),miu_r(i+1),miu_r_max,dp,T,lmd_r_best,wa_r_level);
    else
    [bd_r(i+1),mm_r(i+1),nn_r(i+1)]=modified_control(bd_r(i),wa_r(i),lmd_r(i+1),dt,mm_r(i),nn_r(i),level_1_r,level_2_r,level_3_r,level_r,dp,T);
    end
        
        
    
    a(i+1)=-2*(gd_f(i+1)+gd_r(i+1))/m;%%here we consider two wheels for front or rare direction
    wa_f(i+1)=(gd_f(i+1)*r-bd_f(i+1))/iw;%%definition of positive direction
    wa_r(i+1)=(gd_r(i+1)*r-bd_r(i+1))/iw;
    
    v(i+1)=v(i)+a(i+1)*dt;
    wv_f(i+1)=wv_f(i)+wa_f(i+1)*dt;
    wv_r(i+1)=wv_r(i)+wa_r(i+1)*dt;
    if wv_f(i+1)<0
        wv_f(i+1)=0;
    end
    if wv_r(i)<0
        wv_r(i+1)=0;
    end
    
end
%% figure plot
     figure(1)
     hold on 
     plot(t(1:i),v(1:i))
     plot(t(1:i),r*wv_f(1:i))
     plot(t(1:i),r*wv_r(1:i))
     legend('car speed','front-wheel speed','rear-wheel speed');
     xlabel('time/(s)');
     ylabel('speed/(m/s)');
     figure(2)
     hold on
     plot(t(1:i-100),lmd_f(1:i-100))
     plot(t(1:i-100),lmd_r(1:i-100))
     legend('front lmd','rear lmd');
     xlabel('time/(s)');
     ylabel('slip rate/(1)');
     figure(3)
     hold on
     plot(t(1:i),p_f(1:i))
     plot(t(1:i),p_r(1:i))
     legend('front-wheel pressure force','rear-wheel pressure force');
     xlabel('time/(s)');
     ylabel('pressure force/(N)');
     figure(4)
     hold on 
     plot(t(1:i),wa_f(1:i))
     plot(t(1:i),wa_r(1:i))
     legend('front-wheel angel acceleration','rear-wheel angel acceleration');
     xlabel('time/(s)');
     ylabel('angel acceleration/(s^-2)');
     figure(5)
     hold on
     plot(t(1:i),gd_f(1:i))
     plot(t(1:i),gd_r(1:i))
     legend('front-wheel ground friction','rear-wheel ground friction');
     xlabel('time/(s)');
     ylabel('ground firction/(N)');
     figure(6)
     hold on
     plot(t(1:i),bd_f(1:i))
     plot(t(1:i),bd_r(1:i))
     legend('front-wheel braking moment','rear-wheel braking moment');
     xlabel('time/(s)');
     ylabel('braking torque/(N*m)');
     figure(7)
     hold on
     plot(t(1:i),mm_f(1:i))
     legend('front-wheel control signal');
     xlabel('time/(s)');
     ylabel('logic signal/(1)');