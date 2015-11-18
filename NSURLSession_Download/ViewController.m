//
//  ViewController.m
//  NSURLSession_Download
//
//  Created by vanish on 15/11/18.
//  Copyright (c) 2015年 van7ish. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#define PATH @"http://60.221.222.13/magic.ucloud.com.cn/56305ce8b1258.mp4?wsiphost=local"
@interface ViewController () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSData *resumeData; //保存已经下载到的数据
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) UIButton *btn;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, copy) NSString *file; //下载文件到本地的绝对路径
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) MPMoviePlayerViewController *mpPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(137, 50, 100, 100)];
    [self.view addSubview:_imageView];
    
    _progress = [[UIProgressView alloc] initWithFrame:CGRectMake(10, 200, 355, 10)];
    _progress.progressTintColor = [UIColor redColor];
    [self.view addSubview:_progress];
    
    _label = [[UILabel alloc] initWithFrame:CGRectMake(295, 210, 80, 30)];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.font = [UIFont italicSystemFontOfSize:15];
    [self.view addSubview:_label];
    
    _btn = [UIButton buttonWithType:UIButtonTypeCustom];
    _btn.frame = CGRectMake(138, 250, 100, 30);
    [_btn setTitle:@"开始" forState:UIControlStateNormal];
    _btn.backgroundColor = [UIColor colorWithRed:0.4 green:0.7 blue:0.9 alpha:1];
    [_btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_btn addTarget:self action:@selector(pressBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btn];
    
    
    //创建NSURLSession配置对象
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    //NSURLSession配置对象与NSURLSession对象进行关联
    _session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
}
-(void)pressBtn:(UIButton *)button{
    button.selected = !button.isSelected;//将按钮状态置为未选中状态
    if (_task) { //如果下载任务存在，则调用pause方法
        [self pause];
    }else //如果下载任务不存在，则调用start方法
        [self start];
}
-(void)start{
    if (_resumeData == nil) { //从未下载过数据
        _task = [_session downloadTaskWithURL:[NSURL URLWithString:PATH]];
        //        NSLog(@"开始下载");
        [_btn setTitle:@"暂停" forState:UIControlStateNormal];
    }else if (!_task){ //已下载部分数据，下载任务对象为空，即此时下载任务状态为暂停状态
        _task = [_session downloadTaskWithResumeData:_resumeData];
        //        NSLog(@"继续");
        [_btn setTitle:@"暂停" forState:UIControlStateNormal];
    }
    [_task resume];
}
-(void)pause{
    [_task cancelByProducingResumeData:^(NSData *resumeData) {
        _resumeData = resumeData;//将下载到的数据存入_resumeData中
    }];
    _task = nil;//任务暂停，把下载任务对象置为空
    [_btn setTitle:@"继续" forState:UIControlStateNormal];
    //    NSLog(@"暂停下载");
}

#pragma mark - NSUR bLSessionDownloadDelegate Method
/**
 *  下载任务结束调用方法
 */
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    //拿到沙盒路径的缓存目录
    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    //把沙盒路径的缓存目录和文件名进行拼接，得到文件将要存入的绝对路径(caches目录下)
    _file = [caches stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    
    //把下载完成的文件从tmp目录移动到caches目录下
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr moveItemAtPath:location.path toPath:_file error:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"下载完成" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
    [self showPlayImage];
    //[_btn removeFromSuperview];
    [_btn setTitle:@"下载完成" forState:UIControlStateNormal];
    _btn.enabled = NO;
    [alert show];
}
/**
 *  边下载边写入沙盒路径下的tmp目录
 *
 *  @param session                   NSURLSession对象
 *  @param downloadTask              下载任务对象
 *  @param bytesWritten              <#bytesWritten description#>
 *  @param totalBytesWritten         已经写入的二进制数据长度
 *  @param totalBytesExpectedToWrite 文件总共的二进制数据长度
 */
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    //改变进度条的进度
    double progress = (double)totalBytesWritten / totalBytesExpectedToWrite;
    _progress.progress = progress;
    
    //通过label显示下载进度   对“%”进行转义，写成“%%”
    _label.text = [NSString stringWithFormat:@"%.2f%%", progress * 100];
}
-(void)showPlayImage{
    [_imageView setImage:[UIImage imageNamed:@"play"]];
    _imageView.userInteractionEnabled = YES;
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(play)];
    [_imageView addGestureRecognizer:_tap];
}
/**
 *  播放下载好的视频
 */
-(void)play{
    _mpPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:_file]];
    /**
     *  模拟器需要插入耳机播放
     */
    [self presentMoviePlayerViewControllerAnimated:_mpPlayer];
    //视频播放器没有协议 所以视频播放器触发的事件需要借助通知完成
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishPlay:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}
-(void)finishPlay:(NSNotification *)notify{
    [self.mpPlayer dismissMoviePlayerViewControllerAnimated];
}
@end

