//
//  ZDBGMacros.h
//
//  Created by Lukas Zeller on 2011/03/07.
//  Copyright (c) 2011 by Lukas Zeller. All rights reserved.
//

// macros for debugging
#ifdef DEBUG
// NSLog
#define DBGNSLOG(...) NSLog(__VA_ARGS__)
#if CONSOLEDBG>1
#define DBGEXNSLOG(...) NSLog(__VA_ARGS__)
#else
#define DBGEXNSLOG(...)
#endif
// special types
#define DBGSHOWRECT(s,r) NSLog(s ": x=%f, y=%f, width=%f, height=%f\n",(r).origin.x,(r).origin.y,(r).size.width,(r).size.height)
#define DBGSHOWPOINT(s,p) NSLog(s ": x=%f, y=%f\n",(p).x,(p).y)
#define DBGSHOWSIZE(s,p) NSLog(s ": width=%f, height=%f\n",(p).width,(p).height)
// retain count
#define DBGSHOWRETAIN(s,o) NSLog("(%@) %@.retainCount = %d\n", NSStringFromClass([o class]), s, [o retainCount])
// just object description
#define DBGCFSHOW(cfobj) CFShow(cfobj)

#else

#define DBGNSLOG(...)
#define DBGEXNSLOG(...)

#define DBGSHOWRECT(s,r)
#define DBGSHOWPOINT(s,p)
#define DBGSHOWSIZE(s,p)
#define DBGSHOWRETAIN(s,o)

#define DBGCFSHOW(cfobj)

#endif

/* eof */
