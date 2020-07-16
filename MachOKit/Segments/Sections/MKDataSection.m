//----------------------------------------------------------------------------//
//|
//|             MachOKit - A Lightweight Mach-O Parsing Library
//|             MKDataSection.m
//|
//|             D.V.
//|             Copyright (c) 2014-2015 D.V. All rights reserved.
//|
//| Permission is hereby granted, free of charge, to any person obtaining a
//| copy of this software and associated documentation files (the "Software"),
//| to deal in the Software without restriction, including without limitation
//| the rights to use, copy, modify, merge, publish, distribute, sublicense,
//| and/or sell copies of the Software, and to permit persons to whom the
//| Software is furnished to do so, subject to the following conditions:
//|
//| The above copyright notice and this permission notice shall be included
//| in all copies or substantial portions of the Software.
//|
//| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//| OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//| MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//| IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//| CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//| TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//| SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//----------------------------------------------------------------------------//

#import "MKDataSection.h"
#import "MKInternal.h"
#import "MKNode+MachO.h"
#import "MKOffsetNode+AddressBasedInitialization.h"

//----------------------------------------------------------------------------//
@implementation MKDataSection

//|++++++++++++++++++++++++++++++++++++|//
+ (uint32_t)canInstantiateWithSectionLoadCommand:(id<MKLCSection>)sectionLoadCommand inSegment:(MKSegment*)segment
{
#pragma unused (segment)
    if (self != MKDataSection.class)
        return 0;
    
    // Contrary to what the name of this class may imply, it can handle more
    // than just the __DATA,__data section.  While not a perfect heuristic,
    // a section with the S_REGULAR and no attributes implies a section that
    // contains blobs of data which may be referenced from elsewhere.
    if (sectionLoadCommand.flags == S_REGULAR)
        return 20;
    
    return 0;
}

//|++++++++++++++++++++++++++++++++++++|//
- (void)dealloc
{
    [_children release];
    
    [super dealloc];
}

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  MKPointer
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//|++++++++++++++++++++++++++++++++++++|//
- (MKOptional*)childNodeOccupyingVMAddress:(mk_vm_address_t)address targetClass:(Class)targetClass
{
    // While we could also check whether `address` is _within_ any children, a dict lookup results
    // in a *net* 60x speed-up, and in most cases `address` directly corresponds to a child anyway.
    // It might be possible to increase efficiency of the other lookup method using a trie or a
    // binary search tree but that will probably have a negligible memory improvement and a measurable
    // impact on performance.

    MKOptional *child = [_children[@(address)] childNodeOccupyingVMAddress:address targetClass:targetClass];
    if (child.value)
        return child;

    return [super childNodeOccupyingVMAddress:address targetClass:targetClass];
}

//|++++++++++++++++++++++++++++++++++++|//
- (MKOptional*)childNodeAtVMAddress:(mk_vm_address_t)address targetClass:(Class)targetClass
{
    if (_children == nil)
        _children = [[NSMutableDictionary alloc] init];
    
    MKOffsetNode *child = _children[@(address)];
    if (child == nil && targetClass) {
        NSError *error = nil;
        
        child = [[[targetClass alloc] initWithVMAddress:address inImage:self.macho error:&error] autorelease];
        if (child)
            _children[@(address)] = child;
        else if (error)
            return [MKOptional optionalWithError:error];
    }
    
    if (child)
        return [MKOptional optionalWithValue:child];
    else
        return [super childNodeAtVMAddress:address targetClass:targetClass];
}

//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//
#pragma mark -  MKNode
//◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦◦//

//|++++++++++++++++++++++++++++++++++++|//
- (MKNodeDescription*)layout
{
    // MKDataSection does not describe it's children - they are not its concern.
    return [super layout];
}

@end
