/* Definition of class NSFileCoordinator
   Copyright (C) 2019 Free Software Foundation, Inc.
   
   Implemented by: 	Gregory Casamento <greg.casamento@gmail.com>
   Date: 	Sep 2019
   Original File by: Daniel Ferreira

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.
*/

#import <Foundation/NSFileCoordinator.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFilePresenter.h>
#import <Foundation/NSOperation.h>

static NSMutableArray *__presenters = nil;
static NSMutableDictionary *__presenterMap = nil;

@implementation NSFileAccessIntent
- (instancetype) init
{
  self = [super init];
  if(self != nil)
    {
      _url = nil;
      _isRead = NO;
      _options = 0L;
    }
  return self;
}

+ (instancetype) readingIntentWithURL: (NSURL *)url
                              options: (NSFileCoordinatorReadingOptions)options
{
  NSFileAccessIntent *result = [[self alloc] init];
  ASSIGNCOPY(result->_url, url);
  result->_options = options;
  result->_isRead = YES;
  return result;
}

+ (instancetype) writingIntentWithURL: (NSURL *)url
                              options: (NSFileCoordinatorWritingOptions)options
{
  NSFileAccessIntent *result = [[self alloc] init];
  ASSIGNCOPY(result->_url, url);
  result->_options = options;
  result->_isRead = NO;
  return result;
}

- (NSURL *) URL
{
  return _url;
}
@end

@implementation NSFileCoordinator

+ (void) initialize
{
  if(self == [NSFileCoordinator class])
    {
      __presenters = [[NSMutableArray alloc] init];
      __presenterMap = [[NSMutableDictionary alloc] init];
    }
}

+ (NSArray *) filePresenters
{
  return __presenters;
}

+ (void) addFilePresenter: (id)presenter
{
  [__presenters addObject: presenter];
  [__presenterMap setObject: presenter forKey: [presenter presentedItemURL]];
}

+ (void) removeFilePresenter: (id)presenter
{
  [__presenters removeObject: presenter];
  [__presenterMap removeObjectForKey: [presenter presentedItemURL]];
}

- (NSString *) purposeIdentifier
{
  return _purposeIdentifier;
}

- (void) setPurposeIdentifier: (NSString *)ident  // copy
{
  ASSIGNCOPY(_purposeIdentifier, ident);
}

- (void)cancel
{
  NSEnumerator *en = [__presenters objectEnumerator];
  id obj = nil;
  while((obj = [en nextObject]) != nil)
    {
      id<NSFilePresenter> o = (id<NSFilePresenter>)obj;
      NSOperationQueue *q = [o presentedItemOperationQueue];
      [q cancelAllOperations];
    }
}

- (void)coordinateAccessWithIntents: (NSArray *)intents
                              queue: (NSOperationQueue *)queue
                         byAccessor: (GSAccessorCallbackHandler)accessor
{
  NSEnumerator *en = [intents objectEnumerator];
  id obj = nil;
  
  while((obj = [en nextObject]) != nil)
    {
      NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock: accessor];
      [queue addOperation: op];
    }
}

- (void)coordinateReadingItemAtURL: (NSURL *)readingURL
                           options: (NSFileCoordinatorReadingOptions)readingOptions
                  writingItemAtURL: (NSURL *)writingURL
                           options: (NSFileCoordinatorWritingOptions)writingOptions
                             error: (NSError **)outError
                        byAccessor: (GSNoEscapeReadWriteHandler)readerWriter
{
  if(readingOptions == 0L)
    {
      id<NSFilePresenter> p = [__presenterMap objectForKey: readingURL];
      if([p respondsToSelector: @selector(savePresentedItemChangesWithCompletionHandler:)])
        {
          [p savePresentedItemChangesWithCompletionHandler:NULL]; 
        }
    }
  
  if(writingOptions == 0L)
    {
      id<NSFilePresenter> p = [__presenterMap objectForKey: writingURL];
      if([p respondsToSelector: @selector(savePresentedItemChangesWithCompletionHandler:)])
        {
          [p savePresentedItemChangesWithCompletionHandler:NULL]; 
        }
    }
  CALL_BLOCK(readerWriter, readingURL, writingURL);
}
                 
- (void)coordinateReadingItemAtURL: (NSURL *)url
                           options: (NSFileCoordinatorReadingOptions)options
                             error: (NSError **)outError
                        byAccessor: (GSNoEscapeNewURLHandler)reader
{
  if(options == 0L)
    {
      id<NSFilePresenter> p = [__presenterMap objectForKey: url];
      if([p respondsToSelector: @selector(savePresentedItemChangesWithCompletionHandler:)])
        {
          [p savePresentedItemChangesWithCompletionHandler:NULL]; 
        }
    }
  CALL_BLOCK(reader, url);
}
                 
- (void)coordinateWritingItemAtURL: (NSURL *)url
                           options: (NSFileCoordinatorWritingOptions)options
                             error: (NSError **)outError
                        byAccessor: (GSNoEscapeNewURLHandler)writer
{
  if(options == 0L)
    {
      id<NSFilePresenter> p = [__presenterMap objectForKey: url];
      if([p respondsToSelector: @selector(savePresentedItemChangesWithCompletionHandler:)])
         {
           [p savePresentedItemChangesWithCompletionHandler:NULL]; 
         }
    }
  CALL_BLOCK(writer, url);
}

- (void)coordinateWritingItemAtURL: (NSURL *)url1
                           options: (NSFileCoordinatorWritingOptions)options1
                  writingItemAtURL: (NSURL *)url2
                           options: (NSFileCoordinatorWritingOptions)options2
                             error: (NSError **)outError
                        byAccessor: (GSDualWriteURLCallbackHandler)writer
{
  if(options1 == 0L)
    {
      id<NSFilePresenter> p = [__presenterMap objectForKey: url1];
      if([p respondsToSelector: @selector(savePresentedItemChangesWithCompletionHandler:)])
         {
           [p savePresentedItemChangesWithCompletionHandler:NULL]; 
         }
    }

  if(options2 == 0L)
    {
      id<NSFilePresenter> p = [__presenterMap objectForKey: url2];
      if([p respondsToSelector: @selector(savePresentedItemChangesWithCompletionHandler:)])
         {
           [p savePresentedItemChangesWithCompletionHandler:NULL]; 
         }
    }
  CALL_BLOCK(writer, url1, url2);  
}

- (void)itemAtURL: (NSURL *)oldURL didMoveToURL: (NSURL *)newURL
{
}

- (void)itemAtURL: (NSURL *)oldURL willMoveToURL: (NSURL *)newURL 
{
}

- (void)itemAtURL: (NSURL *)url didChangeUbiquityAttributes: (NSSet *)attributes
{
}

- (void)prepareForReadingItemsAtURLs: (NSArray *)readingURLs
                             options: (NSFileCoordinatorReadingOptions)readingOptions
                  writingItemsAtURLs: (NSArray *)writingURLs
                             options: (NSFileCoordinatorWritingOptions)writingOptions
                               error: (NSError **)outError
                          byAccessor: (GSAccessorHandlerBlock)batchAccessor
{
}

@end
