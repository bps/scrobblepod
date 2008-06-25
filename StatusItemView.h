//
//  StatusItemView.h
//  Statz
//
//  Created by Dave MacLachlan on 2007/11/30.
//  Copyright 2007 Google Inc. All rights reserved.
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.
//

#import <Cocoa/Cocoa.h>


@interface StatusItemView : NSView {
	NSStatusItem *statusItem;

	NSImage *image;
	NSImage *alternateImage;
	id target;
	SEL action;
  
	BOOL selected;
}

- (id)initWithStatusItem:(NSStatusItem*)item;

@property (retain) NSImage *image;
@property (retain) NSImage *alternateImage;
@property (assign) id target;
@property (assign) SEL action;

-(void)setSelected:(BOOL)aBool;
@end