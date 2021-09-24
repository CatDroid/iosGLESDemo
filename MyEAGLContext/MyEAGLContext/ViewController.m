//
//  ViewController.m
//  MyEAGLContext
//
//  Created by hehanlong on 2021/9/22.
//

#import "ViewController.h"
#import "gles/MyGLView.h"
#import "ViewDelegateRender.h"

@interface ViewController ()

@end

@implementation ViewController
{
	ViewDelegateRender* _render ;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_render = [[ViewDelegateRender alloc] init];
	
	MyGLView* view = (MyGLView*)self.view;
	
	view.delegate = _render ;
	
	
}

- (IBAction)onClickDownAddTex:(id)sender
{
	MyGLView* view = (MyGLView*)self.view;
	[view generateTexture];
	
}


- (IBAction)onClickDownDelTex:(id)sender
{
	MyGLView* view = (MyGLView*)self.view;
	[view deleteTexture];
}

@end
