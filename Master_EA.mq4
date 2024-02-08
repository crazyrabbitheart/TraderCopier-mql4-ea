//+------------------------------------------------------------------+
//|                                                  CopyTrading.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


#define EA_NAME "Trade Copy"
#define COMMENT_LABEL_NAME "Trade Copy"

//#define IS_DEMO .
#define DEMO_END_DATE "2024.2.10 07:00"
#define LICENSED_ACCOUNT_NUMBER ""

#import "stdlib.ex4"
string ErrorDescription(int error_code);
#import


struct st_account_detail
  {
   int               account_number;
   int               authorization;
   string            expiry;

  };
st_account_detail m_account_datail = {0,0,""};
string symbols[];

enum noyes
  {
   N=0, // No
   Y=1, // Yes
  };
enum tradeCopyModes
  {
   offMode=0,  // Off
   destinationMode=1,  // Destination
   sourceMode=2,   // Source
  };
struct orderStruct
  {
   string            symbol;
   double            lots;
   ulong             ticket;
   int               direction;
   ENUM_ORDER_TYPE   type;
   ulong             magic;
   double            openPrice;
   double            stopLossPrice;
   double            takeProfitPrice;
   datetime          openTime;
   datetime          openTimeGMT;
   datetime          expiration;
   datetime          expirationGMT;
   string            comment;
   ulong             sourceTicket;
   double            sourceLots;
   ENUM_ORDER_TYPE   sourceType;
   double            originalLots;
   ulong             originalTicket;
   double            sourceOriginalLots;
   ulong             sourceOriginalTicket;
  };
enum lotSizeTypes
  {
   lotSizeType_Risk=0,  // Risk % Of Balance
   lotSizeType_Risk_Margin=3,  // Risk % Of Balance (Including Margin Required)
   lotSizeType_Multiple=1,  // Multiple Of Source
   lotSizeType_Fixed=2,  // Fixed
  };
enum copyOnlyDirections
  {
   copyOnlyDirection_Buy=1, // Only Buy
   copyOnlyDirection_Sell=-1, // Only Sell
   copyOnlyDirection_Both=2, // Buy & Sell
  };
enum timeZones
  {
   timeZones_EEST=1, // EEST
   timeZones_EET=2, // EET
   timeZones_AEST=3, // AEST
   timeZones_AEDT=4, // AEDT
   timeZones_EST=5, // EST
   timeZones_EDT=6, // EDT
   timeZones_JST=7, // JST
  };


int sourceAccountNumber=0;  // Source Account Number
//input double profitLimitEquity = 800; // Profit limit equity
//input double lossLimitEquity = 50;  // Loss limit equity

tradeCopyModes tradeCopyMode=2;  // Trade Copy Mode
int destinationAccountNumber=0;  // Destination Account Number
noyes invertTradeCopyDirection=0;  // Invert Trade Copy
double lotSizeMultipleOfSource=1.0;  // Lot Size Multiple Of Source
string header1="--------------- DESTINATION ONLY ---------------";  // --------------- DESTINATION ONLY ---------------
noyes openTradesInDestination=1;  // Open Trades in Destination?
noyes openPendingOrdersInDestination=1;  // Open Pending Orders in Destination?
copyOnlyDirections copyOnlyDirection=2;  // Copy Direction
noyes copyTPToDestination=1;  // Copy TP To Destination?
double overrideDestinationTP=0;  // Override Destination TP (Points)
noyes copySLToDestination=1;  // Copy SL To Destination?
double overrideDestinationSL=0;  // Override Destination SL (Points)
noyes closeTradesInDestination=1;  // Close Trades in Destination?
noyes deletePendingInDestination=1; // Delete Pending Orders in Destination?

string header2="";  // |
lotSizeTypes lotSizeType=1; // Lot Size Type
double lotSizeRiskPercent=0.50;  // Lot Size Risk %
//double lotSizeMultipleOfSource=1.0;  // Lot Size Multiple Of Source
double lotSizeFixed=0.01; // Fixed Lot Size
double minLotSize=0.01; // Minimum Lot Size
double maxLotSize=100.00;   // Maximum Lot Size
string header3="";  // |
int maximumOrders=0;  // Maximum Orders In Destination (0 = Unlimited)
int maximumSlippage=0;   // Maximum Open Price Slippage (Points) (Not Supported By All Brokers)
int maximumPriceDeviationPoints=0; // Maximum Open Price Deviation To Copy (Points)
int maximumTimeAfterSourceOpenSecs=0;   // Maximum Time After Source Open (secs)
string header4="";  // |
double dailyProfitPercentToStop=0;  // Daily Profit % To Stop
noyes dailyProfitPercentCloseTrades=0; // Close Trades When Daily Profit % Is Reached?
double dailyLossPercentToStop=0;  // Daily Loss % To Stop
noyes dailyLossPercentCloseTrades=0; // Close Trades When Daily Loss % Is Reached?
string header5="";  // |
noyes sendAlertForNewTrades=0;   // Send Alert For New Trades?
noyes sendAlertForClosedTrades=0;   // Send Alert For Closed Trades?
noyes sendAlertForPartiallyClosedTrades=0;   // Send Alert For Partially Closed Trades?
noyes sendAlertForDailyProfitPercentReached=0; // Send Alert For Daily Profit % Reached
noyes sendAlertForDailyLossPercentReached=0; // Send Alert For Daily Loss % Reached
noyes alertSound=0;  // Alert Sound?
noyes alertPopup=0;  // Alert Popup?
noyes alertEmail=0;  // Alert Email?
noyes alertMobile=0;   // Alert Mobile?
string header6="-------------- SOURCE & DESTINATION --------------";  // -------------- SOURCE & DESTINATION --------------
timeZones brokerServerSummerTimeZone=1;  // Broker Server Summer Time Zone
timeZones brokerServerWinterTimeZone=2;  // Broker Server Winter Time Zone
string symbolPrefix="";   // Broker Symbol Prefix
string symbolSuffix="";   // Broker Symbol Suffix
color LabelColor=clrBlack; // Message Color

string header7="-----------------Trailing Stop-----------------";
noyes  ApplyTrailingStop = 0;
bool   ProfitTrailing = True;
int    TrailingStop   = 8;
int    TrailingStep   = 2;
string header8="-----------------Time on/off-------------------";
noyes ApplyOnOffTime = 0;
int   OnHour = 2;
int   OnMinute = 0;
int   OffHour = 17;
int   OffMinute = 30;
string header9="-------------Select Pairs in Destination---------";
noyes  ApplyDestinationPair = 0;
string destinationPair = "EURUSD;USDCHF;GBPUSD";
string header10="----------Apply Send Message and Filling log file---------";
noyes  ApplyMessageLog = 1;

bool disable=false,completed=false;
orderStruct sourceOrders[]= {},lastSourceOrders[]= {},destinationOrders[]= {};
string ermsg="",sourceOrdersFile="",destinationOrdersFile="",stopTodayFile="",summerTimeZone,winterTimeZone,log1="";
int tradeDirection=0,sizeLastSourceOrders=0,sizeSourceOrders=0,sizeDestinationOrders=0;
int tradeCopyTimerMilliseconds=100;
double lastDailyProfitPercentToStop=0,lastDailyLossPercentToStop=0;
datetime lastOpenTimeLog=0;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   sourceAccountNumber = AccountNumber();

#ifdef IS_DEMO
   datetime cDate=TimeCurrent(),lDate=TimeLocal(),eDate=StringToTime(DEMO_END_DATE);
   if(cDate>=eDate || lDate>=eDate)
     {
      if(ApplyMessageLog)
         Alert("Demo Version Expires "+(string)eDate);
      return(INIT_AGENT_NOT_SUITABLE);
     }
#endif
   if(IsTesting())
      return(INIT_AGENT_NOT_SUITABLE);
//if (!LicenseCheck()) return(INIT_PARAMETERS_INCORRECT);
   Comment("");
   DeleteCommentLabels();
   string msg="";
   lastOpenTimeLog=0;
   log1="";
   disable=completed=false;
   ChartSettings("OldLace");
   if(ApplyMessageLog)
      CreateCommentLabels();
//--On/Off Time--
   if(ApplyOnOffTime)
     {
      //Print("CurH=\n", TimeHour(TimeLocal()));
      //Print("CurM=\n", TimeMinute(TimeLocal()));
      if(TimeHour(TimeLocal())>=OffHour && TimeMinute(TimeLocal())>=OffMinute)
        {
         LPrint("Off Time");
         return(INIT_SUCCEEDED);
        }
      //Print("Pass Off Time\n");
      if(!(TimeHour(TimeLocal())>=OnHour && TimeMinute(TimeLocal())>=OnMinute))
        {
         LPrint("Not On Time");
         return(INIT_SUCCEEDED);
        }
      //Print("Pass On Time\n");
      CommentLabelText(25,"");
      CommentLabelText(6,"");
     }


//---------------
   if(AccountNumber()==0)
     {
      LPrint("Not Logged In To Any Account");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(sourceAccountNumber==0)
     {
      LPrint("Missing Source Account Number");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==1 && destinationAccountNumber==0)
     {
      LPrint("Missing Destination Account Number");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==2 && destinationAccountNumber!=0)
     {
      LPrint("Destination Account Number Must Be 0 In Source Mode");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==2 && sourceAccountNumber!=AccountNumber())
     {
      LPrint("Invalid Source Account Number ("+(string)sourceAccountNumber+")");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==1 && destinationAccountNumber!=AccountNumber())
     {
      LPrint("Invalid Destination Account Number ("+(string)destinationAccountNumber+")");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==1 && destinationAccountNumber==sourceAccountNumber)
     {
      LPrint("Destination Account Number Cannot Be The Same As Source Account Number ("+(string)destinationAccountNumber+")");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==1 && copySLToDestination==0 && (lotSizeType==0 || lotSizeType==3))
     {
      LPrint("\"Lot Size By Risk % Of Balance\" Requires \"Copy SL To Destination\"");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==1 && dailyLossPercentToStop<0)
     {
      LPrint("\"Daily Losee % To Stop\" Must Be Positive");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode==1 && dailyProfitPercentToStop<0)
     {
      LPrint("\"Daily Profit % To Stop\" Must Be Positive");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if((bool)ChartGetInteger(0,CHART_IS_OFFLINE))
     {
      disable=true;
      LPrint("Chart Is Offline");
      return(INIT_SUCCEEDED);
     }
   if(lotSizeType==2 && !ValidLotSize(Symbol(),lotSizeFixed))
     {
      LPrint("Invalid Fixed Lot Size For "+Symbol()+" ("+(string)lotSizeFixed+")");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if((summerTimeZone=TimeZoneFromCode(brokerServerSummerTimeZone))=="")
     {
      LPrint("Unrecognized Broker Server Summer Time Zone ("+(string)brokerServerSummerTimeZone+")");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if((winterTimeZone=TimeZoneFromCode(brokerServerWinterTimeZone))=="")
     {
      LPrint("Unrecognized Broker Server Winter Time Zone ("+(string)brokerServerWinterTimeZone+")");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   ClosedAccountProfitToday(true);
   sourceOrdersFile="TradeCopy\\Source Orders "+(string)sourceAccountNumber+".txt";
   destinationOrdersFile="TradeCopy\\Destination Orders "+(string)sourceAccountNumber+" To "+(string)AccountNumber()+".txt";
   stopTodayFile="TradeCopy\\Stop Today "+(string)sourceAccountNumber+" To "+(string)AccountNumber()+".txt";
   if(lastDailyProfitPercentToStop!=dailyProfitPercentToStop || lastDailyLossPercentToStop!=dailyLossPercentToStop || (dailyProfitPercentToStop==0 && dailyLossPercentToStop==0))
     {
      lastDailyLossPercentToStop=dailyLossPercentToStop;
      lastDailyProfitPercentToStop=dailyProfitPercentToStop;
      if(FileIsExist(stopTodayFile))
         FileDelete(stopTodayFile);
     }
   sizeDestinationOrders=sizeSourceOrders=sizeLastSourceOrders=0;
   if(tradeCopyMode==1 && !GetDestinationOrdersFromFile())
     {
      LPrint("Cannot Read Destination Orders Or Recognize Symbols");
      disable=true;
      return(INIT_SUCCEEDED);
     }
   if(tradeCopyMode!=0 && !EventSetMillisecondTimer(tradeCopyTimerMilliseconds))
     {
      CommentLabelText(5,msg="Tick Mode");
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Comment("");
   DeleteCommentLabels();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() { 
   TradeCopyMain(); 
   //Print("master----ontick", _Symbol);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() { 
   TradeCopyMain(); 
   //Print("master----ontimer", _Symbol);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeCopyMain()
  {
   if(IsTesting() || tradeCopyMode==0)
      return;


//--On/Off Time--
   if(ApplyOnOffTime)
     {
      if(TimeHour(TimeLocal())>=OffHour && TimeMinute(TimeLocal())>=OffMinute)
        {
         CommentLabelText(6,"Off Time");
         return;
        }
      if(!(TimeHour(TimeLocal())>=OnHour && TimeMinute(TimeLocal())>=OnMinute))
        {
         CommentLabelText(6,"Not On Time");
         return;
        }
      CommentLabelText(25,"");
      CommentLabelText(6,"");
     }
//---------------


   string msg="";
   if(disable)
     {
      Comment(msg=EA_NAME+" Disabled");
      CommentLabelText(6,msg);
      EventKillTimer();
      return;
     }
   if(tradeCopyMode==1 && IsTradeContextBusy())
     {
      CommentLabelText(6,"Terminal Is Busy");
      return;
     }
   if(tradeCopyMode==1 && !IsTradeAllowed())
     {
      CommentLabelText(6,"- AUTOMATED TRADING IS OFF -");
      return;
     }
   if(tradeCopyMode==1 && AccountNumber()!=destinationAccountNumber)
     {
      CommentLabelText(6,"Not Logged In To The Destination Account ("+(string)destinationAccountNumber+")");
      return;
     }
   if(tradeCopyMode==2 && AccountNumber()!=sourceAccountNumber)
     {
      CommentLabelText(6,"Not Logged In To The Source Account ("+(string)sourceAccountNumber+")");
      return;
     }

   if(tradeCopyMode==2)
     {
      bool bEARemove = false;
      //if(AccountEquity() >= profitLimitEquity || AccountEquity() <= lossLimitEquity)
      //{
      //   CloseAllTrades();
      //   bEARemove = true;
      //}
      CreateSourceOrdersFile();
      if (bEARemove)
      {
         //ExpertRemove();
         ChartRedraw();
      }
      return;
     }
   if(tradeCopyMode!=1)
      return;
   CommentLabelText(6,"Active");
   ManageOrders();
   CommentLabelText(3,"");
   if(FileIsExist(stopTodayFile))
     {
      CommentLabelText(1,"Daily Profit/Loss % Reached");
      return;
     }
   else
      CommentLabelText(1,"");
   if(!FileIsExist(sourceOrdersFile,FILE_COMMON))
      return;
   ResetSourceOrders();
   if(!GetSourceOrdersFromFile())
      return;

   bool bChange = SourceOrdersChanged();
   if(completed && !bChange)
      return;
   CommentLabelText(2,"");
   if(!UpdateDestinationOrders())
     {
      completed=false;
      return;
     }
   completed=true;


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ManageOrders()
  {
   string msg="";
//-------Trailing Stop-------
   if(ApplyTrailingStop)
     {
      for(int i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
           {
            TrailingPositions();
           }
        }
     }
//--------------------------

   if(FileIsExist(stopTodayFile))
     {
      datetime stopDate=StopTodayDate(),todayDate=StringToTime(TimeToString(TimeCurrent(),TIME_DATE)+" 00:00");
      if(todayDate>stopDate)
         FileDelete(stopTodayFile);
     }
   if(!FileIsExist(stopTodayFile) && (dailyProfitPercentToStop>0 || dailyLossPercentToStop>0))
     {
      double closedProfit=ClosedAccountProfitToday(),netProfit=closedProfit+AccountProfit(),balance0=AccountBalance()-closedProfit;
      if(dailyProfitPercentToStop>0 && netProfit>0 && netProfit/balance0*100.0>=dailyProfitPercentToStop)
        {
         WriteStopTodayFile();
         LPrint(msg="Daily Profit Of "+(string)dailyProfitPercentToStop+"% Reached");
         if(sendAlertForDailyProfitPercentReached==1)
            SendAlert(msg);
         if(dailyProfitPercentCloseTrades==1)
            CloseAllTrades();
        }
      else
         if(dailyLossPercentToStop>0 && netProfit<0 && MathAbs(netProfit)/balance0*100.0>=dailyLossPercentToStop)
           {
            WriteStopTodayFile();
            LPrint(msg="Daily Loss Of "+(string)dailyLossPercentToStop+"% Reached");
            if(sendAlertForDailyLossPercentReached==1)
               SendAlert(msg);
            if(dailyLossPercentCloseTrades==1)
               CloseAllTrades();
           }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteStopTodayFile()
  {
   int fH=FileOpen(stopTodayFile,FILE_WRITE|FILE_TXT);
   if(fH==INVALID_HANDLE)
      return;
   FileWriteString(fH,TimeToString(TimeCurrent()));
   FileClose(fH);
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime StopTodayDate()
  {
   if(!FileIsExist(stopTodayFile))
      return(0);
   int fH=FileOpen(stopTodayFile,FILE_READ|FILE_SHARE_READ|FILE_TXT);
   if(fH==INVALID_HANDLE)
      return(0);
   string str=FileReadString(fH);
   FileClose(fH);
   return(StringToTime(StringTrimLeft(StringTrimRight(str))));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseAllTrades()
  {
   int orderI,ordersTotal=OrdersTotal();
   bool res=true;
   for(orderI=0; orderI<ordersTotal; orderI++)
      if(OrderSelect(orderI,SELECT_BY_POS,MODE_TRADES) && OrderCloseTime()==0)
        {
         if(OrderType()==OP_BUY || OrderType()==OP_SELL)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),(OrderType()==OP_BUY ? CurrentBid(OrderSymbol()) : CurrentAsk(OrderSymbol())),0,clrNONE))
               res=false;
            else
               orderI--;
           }
         else
            if(!OrderDelete(OrderTicket(),clrNONE))
               res=false;
            else
               orderI--;
        }
   return(res);
  }
//---TrailingStop-----
void TrailingPositions()
  {
   double pBid, pAsk, pp, myTS;
   bool res;

   pp = MarketInfo(OrderSymbol(), MODE_POINT);
   double default_sp = MarketInfo(OrderSymbol(), MODE_STOPLEVEL);
   if(default_sp > TrailingStop)
      myTS = default_sp;
   else
      myTS = TrailingStop;
//Print(StringConcatenate("------------------------------  =>", default_sp));
   if(OrderType()==OP_BUY)
     {
      pBid = MarketInfo(OrderSymbol(), MODE_BID);
      if(!ProfitTrailing || (pBid-OrderOpenPrice())>myTS*pp)
        {
         if(OrderStopLoss()<pBid-(myTS+TrailingStep-1)*pp)
           {
            res = OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(pBid-myTS*pp, Digits),OrderTakeProfit(),0,clrNONE);
            if(!res)
               if(ApplyMessageLog)
                  Print("Error in OrderModify for Buy. Error code=",GetLastError());
               else
                  if(ApplyMessageLog)
                     Print("Buy Order modified successfully by TrailinStop.");
            return;
           }
        }
     }
   if(OrderType()==OP_SELL)
     {
      pAsk = MarketInfo(OrderSymbol(), MODE_ASK);
      if(!ProfitTrailing || OrderOpenPrice()-pAsk>myTS*pp)
        {
         if(OrderStopLoss()>pAsk+(myTS+TrailingStep-1)*pp || OrderStopLoss()==0)
           {
            res = OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(pAsk+myTS*pp, Digits),OrderTakeProfit(),0,clrNONE);
            if(!res)
               if(ApplyMessageLog)
                  Print("Error in OrderModify for Sell. Error code=",GetLastError());
               else
                  if(ApplyMessageLog)
                     Print("Sell Order modified successfully by TrailinStop.");
            return;
           }
        }
     }
  }
//-----------------------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UpdateDestinationOrders()
  {
   if(sizeSourceOrders==0 && sizeDestinationOrders==0)
      return(true);
   int s,d,er,direction;
   string symbol,msg="",comment,message1="",message2="",message3="";
   double closeLots=0,lots,closePrice,openPrice,tP,sL;
   bool found=false,res=false,doneAll=true,pending;
   ulong ticket,newTicket,magic;
   datetime expiration;
   ENUM_ORDER_TYPE type;
   for(d=0; d<sizeDestinationOrders; d++)
     {
      found=false;
      ticket=destinationOrders[d].ticket;
      symbol=destinationOrders[d].symbol;
      direction=destinationOrders[d].direction;
      //---ApplyDestinationPair---
      if(ApplyDestinationPair)
        {
         if(StringFind(destinationPair, symbol, 0) == -1)
            continue;
        }
      //--------------------------
      for(s=0; s<sizeSourceOrders; s++)
         if(destinationOrders[d].sourceOriginalTicket==sourceOrders[s].originalTicket)
           {
            found=true;
            break;
           }
      if(!found)
        {
         if(!OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES) || OrderCloseTime()!=0)
           {
            if(OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_HISTORY))
              {
               RemoveDestinationOrder(ticket);
               d--;
               continue;
              }
            else
              {
               doneAll=false;
               continue;
              }
           }
         type=(ENUM_ORDER_TYPE)OrderType();
         if(type==OP_BUY || type==OP_SELL)
           {
            if(closeTradesInDestination==0)
               continue;
            closePrice=(direction==1 ? CurrentBid(symbol) : CurrentAsk(symbol));
            if(sendAlertForClosedTrades==1)
               SendAlert("Close "+DoubleToString(OrderLots(),LotSizeDigits(symbol))+" "+symbol+" "+(direction==1 ? "Long" : "Short")+" #"+(string)ticket);
            ResetLastError();
            if(OrderClose((int)ticket,OrderLots(),closePrice,0,clrNONE))
              {
               RemoveDestinationOrder(ticket);
               d--;
               continue;
              }
            LPrint("Cannot Close "+symbol+" #"+(string)ticket+" Type:"+(string)type+" #"+(string)(er=GetLastError())+" "+ErrorDescription(er));
            doneAll=false;
           }
         else
           {
            if(deletePendingInDestination==0)
               continue;
            if(OrderDelete((int)ticket,clrNONE))
              {
               RemoveDestinationOrder(ticket);
               d--;
               continue;
              }
            LPrint("Cannot Delete "+symbol+" #"+(string)ticket+" Type:"+(string)type+" #"+(string)(er=GetLastError())+" "+ErrorDescription(er));
            doneAll=false;
           }
         continue;
        }
      if(!OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES) || OrderCloseTime()!=0)
        {
         if(OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_HISTORY))
           {
            message2=symbol+" #"+(string)destinationOrders[d].ticket+" From Source #"+(string)sourceOrders[s].ticket+" Has Closed";
            continue;
           }
         else
           {
            doneAll=false;
            continue;
           }
        }
      type=(ENUM_ORDER_TYPE)OrderType();
      pending=(type!=OP_BUY && type!=OP_SELL);
      openPrice=(pending ? NormalizeDouble(sourceOrders[s].openPrice,Dig(symbol)) : OrderOpenPrice());
      SetTPSL(symbol,openPrice,direction,s,tP,sL);
      closeLots=0;
      if(copyTPToDestination==0 || tP==destinationOrders[d].takeProfitPrice)
         tP=-1;
      if(copySLToDestination==0 || sL==destinationOrders[d].stopLossPrice)
         sL=-1;
      if(pending)
        {
         expiration=ConvertGMTToServerTime(sourceOrders[s].expirationGMT);
         if(tP==-1 && sL==-1 && expiration==destinationOrders[d].expiration && openPrice==destinationOrders[d].openPrice)
            continue;
        }
      else
        {
         if(sourceOrders[s].originalLots!=sourceOrders[s].lots)
           {
            closeLots=LotStepFloor(OrderLots()-LotStepFloor(sourceOrders[s].lots/sourceOrders[s].originalLots*destinationOrders[d].originalLots,symbol),symbol);
            if(closeLots<0 || closeLots==OrderLots())
               closeLots=0;
           }
         if(tP==-1 && sL==-1 && closeLots==0)
            continue;
         expiration=OrderExpiration();
        }
      if(pending || tP>0 || sL>0)
        {
         if(tP==-1)
            tP=OrderTakeProfit();
         if(sL==-1)
            sL=OrderStopLoss();
         ResetLastError();
         if(!(res=OrderModify((int)ticket,openPrice,sL,tP,expiration,clrNONE)))
           {
            message3="Cannot Modify "+symbol+" #"+(string)ticket+" ("+(string)(er=GetLastError())+") "+ErrorDescription(er);
            doneAll=false;
           }
         else
            ModifyDestinationOrder(ticket,s,d);
        }
      if(closeLots>0)
        {
         if(sendAlertForPartiallyClosedTrades==1)
            SendAlert("Partially Close "+DoubleToString(closeLots,LotSizeDigits(symbol))+" "+symbol+" "+(direction==1 ? "Long" : "Short")+" #"+(string)ticket);
         closePrice=(destinationOrders[d].direction==1 ? CurrentBid(symbol) : CurrentAsk(symbol));
         ResetLastError();
         if(!(res=OrderClose((int)ticket,closeLots,closePrice,0,clrNONE)))
           {
            message3="Cannot Close "+(string)closeLots+" Of "+(string)OrderLots()+" "+symbol+" #"+(string)ticket+" ("+(string)(er=GetLastError())+") "+ErrorDescription(er);
            doneAll=false;
           }
         else
           {
            ResetLastError();
            if((newTicket=TicketAfterPartialClose(ticket))==0)
              {
               LPrint("Cannot Find New Ticket After Partial Close "+(string)closeLots+" Of "+(string)OrderLots()+" "+symbol+" #"+(string)ticket+" ("+(string)(er=GetLastError())+") "+ErrorDescription(er));
               doneAll=false;
              }
            else
               ModifyDestinationOrder((ticket=newTicket),s,d);
           }
        }
     }
   if(maximumOrders>0 && OrdersTotal()>=maximumOrders)
      message2="Maximum Orders ("+(string)maximumOrders+") Reached";
   else
      for(s=0; s<sizeSourceOrders; s++)
        {
         found=false;
         for(d=0; d<sizeDestinationOrders; d++)
            if(destinationOrders[d].sourceOriginalTicket==sourceOrders[s].originalTicket)
              {
               found=true;
               break;
              }
         if(found)
            continue;
         if(!IsTradeAllowed((symbol=sourceOrders[s].symbol),TimeCurrent()))
           {
            message1="Cannot Copy "+symbol+" #"+(string)sourceOrders[s].ticket+" (Busy Or Not Allowed)";
            doneAll=false;
            continue;
           }
         direction=sourceOrders[s].direction*(invertTradeCopyDirection==1 ? -1 : 1);
         if((copyOnlyDirection==1 && direction==-1) || (copyOnlyDirection==-1 && direction==1))
            continue;
         type=sourceOrders[s].type;
         if(invertTradeCopyDirection==1)
            type=InvertType(type);
         pending=(type!=OP_BUY && type!=OP_SELL);
         if((lotSizeType==0 || lotSizeType==3) && overrideDestinationSL==0 && sourceOrders[s].stopLossPrice==0)
           {
            message1="Cannot Copy "+symbol+" #"+(string)sourceOrders[s].ticket+" Using Risk % Without SL";
            doneAll=false;
            continue;
           }
         if(!pending && maximumTimeAfterSourceOpenSecs>0 && (int)TimeGMT()-(int)sourceOrders[s].openTimeGMT>maximumTimeAfterSourceOpenSecs)
           {
            message1=symbol+" #"+(string)sourceOrders[s].ticket+" Is Past Maximum Open Time";
            if(lastOpenTimeLog==0 || (int)TimeCurrent()-(int)lastOpenTimeLog>=3600)
              {
               if(ApplyMessageLog)
                  Print(symbol+" #"+(string)sourceOrders[s].ticket+" Maximum Time (secs):"+(string)maximumTimeAfterSourceOpenSecs+" Source Open Time:"+(string)sourceOrders[s].openTime+" Source Open Time GMT:"+(string)sourceOrders[s].openTimeGMT+" OS Time Local:"+(string)TimeLocal()+" OS Time GMT:"+(string)TimeGMT()+" Difference:"+(string)((int)TimeGMT()-(int)sourceOrders[s].openTimeGMT));
               lastOpenTimeLog=TimeCurrent();
              }
            doneAll=false;
            continue;
           }
         openPrice=(pending ? NormalizeDouble(sourceOrders[s].openPrice,Dig(symbol)) : (direction==1 ? CurrentAsk(symbol) : CurrentBid(symbol)));
         SetTPSL(symbol,openPrice,direction,s,tP,sL);
         if((lots=GetLots(symbol,s,sL,direction,openPrice))==0)
            continue;
         if(!pending && maximumPriceDeviationPoints>0 && direction*(openPrice-sourceOrders[s].openPrice)>(double)maximumPriceDeviationPoints*PointSize(symbol))
           {
            message1=symbol+" #"+(string)sourceOrders[s].ticket+" Is Past Maximum Price Deviation";
            doneAll=false;
            continue;
           }
         if(!pending && openTradesInDestination==0 && sendAlertForNewTrades==1)
            SendAlert(DoubleToString(lots,LotSizeDigits(symbol))+" "+symbol+" "+(type==OP_BUY ? "Long" : "Short")+" "+"S/L:"+" "+(string)sL+" "+"T/P:"+" "+(string)tP);
         if((pending && openPendingOrdersInDestination==0) || (!pending && openTradesInDestination==0))
            continue;
         comment=sourceOrders[s].comment;
         magic=sourceOrders[s].magic;
         expiration=(pending ? sourceOrders[s].expiration : 0);
         ResetLastError();
         if(ApplyDestinationPair)
           {
            if(StringFind(destinationPair, symbol, 0) != -1)
              {
               if((ticket=OrderSend(symbol,(int)type,lots,openPrice,maximumSlippage,sL,tP,comment,(int)magic,expiration,clrNONE))<0)
                 {
                  LPrint("Cannot Open "+(string)lots+" "+symbol+" Type:"+(string)type+" #"+(string)(er=GetLastError())+" "+ErrorDescription(er));
                  doneAll=false;
                  continue;
                 }
               else
                  if(!pending && sendAlertForNewTrades==1)
                     SendAlert(DoubleToString(lots,LotSizeDigits(symbol))+" "+symbol+" "+(type==OP_BUY ? "Long" : "Short")+" "+"S/L:"+" "+(string)sL+" "+"T/P:"+" "+(string)tP);
               AddDestinationOrder(ticket,s);
               if(doneAll && log1!="")
                 {
                  if(ApplyMessageLog)
                     Print(log1);
                  log1="";
                 }
              }
           }
         else
           {
            if((ticket=OrderSend(symbol,(int)type,lots,openPrice,maximumSlippage,sL,tP,comment,(int)magic,expiration,clrNONE))<0)
              {
               LPrint("Cannot Open "+(string)lots+" "+symbol+" Type:"+(string)type+" #"+(string)(er=GetLastError())+" "+ErrorDescription(er));
               doneAll=false;
               continue;
              }
            else
               if(!pending && sendAlertForNewTrades==1)
                  SendAlert(DoubleToString(lots,LotSizeDigits(symbol))+" "+symbol+" "+(type==OP_BUY ? "Long" : "Short")+" "+"S/L:"+" "+(string)sL+" "+"T/P:"+" "+(string)tP);
            AddDestinationOrder(ticket,s);
            if(doneAll && log1!="")
              {
               if(ApplyMessageLog)
                  Print(log1);
               log1="";
              }
           }
        }
   CommentLabelText(1,message1);
   CommentLabelText(2,message2);
   CommentLabelText(3,message3);
   return(doneAll);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLots(string symbol,int s,double sL,int direction,double openPrice)
  {
   double lots=0;
   if(lotSizeType==2)
      lots=lotSizeFixed;
   else
      if(lotSizeType==1)
         lots=LotStepFloor(lotSizeMultipleOfSource*sourceOrders[s].lots,symbol);
      else
         if(lotSizeType==0 || lotSizeType==3)
            lots=LotSizeByRisk(symbol,(int)MathRound(MathAbs(openPrice-sL)/PointSize(symbol)),(lotSizeType==3));
   if(!ValidLotSize(symbol,lots))
      return(0);
   return(lots);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SetTPSL(string symbol,double openPrice,int direction,int s,double &tP,double &sL)
  {
   if(overrideDestinationSL>0)
      sL=NormalizeDouble(openPrice-direction*(double)overrideDestinationSL*PointSize(symbol),Dig(symbol));
   else
      sL=(copySLToDestination==1 ? NormalizeDouble((invertTradeCopyDirection==1 ? sourceOrders[s].takeProfitPrice : sourceOrders[s].stopLossPrice),Dig(symbol)) : 0);
   if(overrideDestinationTP>0)
      tP=NormalizeDouble(openPrice+direction*(double)overrideDestinationTP*PointSize(symbol),Dig(symbol));
   else
      tP=(copyTPToDestination==1 ? NormalizeDouble((invertTradeCopyDirection==1 ? sourceOrders[s].stopLossPrice : sourceOrders[s].takeProfitPrice),Dig(symbol)) : 0);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateSourceOrdersFile()
  {
   int fH,i,j,orderI=0,ordersTotal,commentInt=0,lotSizeDigits,direction;
   ENUM_ORDER_TYPE orderType;
   ulong originalTicket=0,ticket;
   double originalLots=0;
   bool changed=false,oSRes=true,found=false,cancel=false;
   string comment,str,commentStr="",tag;
   if((ordersTotal=GetOrdersTotal())==-1)
      return(false);
   if(ordersTotal==0 && sizeSourceOrders>0)
     {
      found=false;
      for(i=0; i<sizeSourceOrders; i++)
         if(!OrderSelect((int)sourceOrders[i].ticket,SELECT_BY_TICKET,MODE_HISTORY) || OrderCloseTime()==0)
           {
            found=true;
            break;
           }
      if(found)
         return(false);
     }
   ResetSourceOrders();
   for(orderI=0; orderI<ordersTotal; orderI++)
      if(oSRes=OrderSelect(orderI,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderCloseTime()!=0)
           {
            cancel=true;
            break;
           }
         if((orderType=(ENUM_ORDER_TYPE)OrderType())==OP_BUY || orderType==OP_BUYSTOP || orderType==OP_BUYLIMIT)
            direction=1;
         else
            if(orderType==OP_SELL || orderType==OP_SELLSTOP || orderType==OP_SELLLIMIT)
               direction=-1;
            else
              {
               cancel=true;
               break;
              }
         ticket=OrderTicket();
         found=false;
         for(j=0; j<sizeLastSourceOrders; j++)
            if(lastSourceOrders[j].ticket==ticket)
              {
               found=true;
               break;
              }
         if(found)
           {
            originalLots=lastSourceOrders[j].originalLots;
            originalTicket=lastSourceOrders[j].originalTicket;
           }
         else
            if(OriginalPartialClose(orderI,originalTicket,originalLots)<0)
              {
               cancel=true;
               break;
              }
         ArrayResize(sourceOrders,sizeSourceOrders+1,10);
         sourceOrders[sizeSourceOrders].symbol=OrderSymbol();
         sourceOrders[sizeSourceOrders].lots=OrderLots();
         sourceOrders[sizeSourceOrders].ticket=ticket;
         sourceOrders[sizeSourceOrders].direction=direction;
         sourceOrders[sizeSourceOrders].type=orderType;
         sourceOrders[sizeSourceOrders].magic=OrderMagicNumber();
         sourceOrders[sizeSourceOrders].openPrice=OrderOpenPrice();
         sourceOrders[sizeSourceOrders].stopLossPrice=OrderStopLoss();
         sourceOrders[sizeSourceOrders].takeProfitPrice=OrderTakeProfit();
         sourceOrders[sizeSourceOrders].openTime=OrderOpenTime();
         sourceOrders[sizeSourceOrders].openTimeGMT=ConvertServerTimeToGMT(OrderOpenTime());
         sourceOrders[sizeSourceOrders].expiration=OrderExpiration();
         sourceOrders[sizeSourceOrders].expirationGMT=ConvertServerTimeToGMT(OrderExpiration());
         sourceOrders[sizeSourceOrders].comment=OrderComment();
         sourceOrders[sizeSourceOrders].sourceTicket=(ticket=OrderTicket());
         sourceOrders[sizeSourceOrders].sourceLots=OrderLots();
         sourceOrders[sizeSourceOrders].sourceType=(ENUM_ORDER_TYPE)OrderType();
         sourceOrders[sizeSourceOrders].originalLots=originalLots;
         sourceOrders[sizeSourceOrders].originalTicket=originalTicket;
         sourceOrders[sizeSourceOrders].sourceOriginalLots=0;
         sourceOrders[sizeSourceOrders].sourceOriginalTicket=0;
         sizeSourceOrders++;
        }
   if(cancel || !oSRes)
      return(false);
   //Print("sourceOrdersFile",sourceOrdersFile);
   if(FileIsExist(sourceOrdersFile,FILE_COMMON) && !SourceOrdersChanged())
      return(true);
   if((fH=FileOpen(sourceOrdersFile,FILE_COMMON|FILE_WRITE|FILE_CSV|FILE_ANSI,"\t"))==INVALID_HANDLE)
      return(false);
   for(i=0; i<sizeSourceOrders; i++)
     {
      lotSizeDigits=LotSizeDigits(sourceOrders[i].symbol);
      if(NormalizeSymbol(sourceOrders[i].symbol)=="")
        {
         CommentLabelText(8,"Cannot Normalize "+sourceOrders[i].symbol+" Using Broker Symbol Prefix/Suffix");
         cancel=true;
         break;
        }
      FileWrite(fH,
                NormalizeSymbol(sourceOrders[i].symbol),
                DoubleToString(sourceOrders[i].lots,lotSizeDigits),
                sourceOrders[i].ticket,
                sourceOrders[i].direction,
                (int)sourceOrders[i].type,
                sourceOrders[i].magic,
                DoubleToString(sourceOrders[i].openPrice,Dig(sourceOrders[i].symbol)),
                DoubleToString(sourceOrders[i].stopLossPrice,Dig(sourceOrders[i].symbol)),
                DoubleToString(sourceOrders[i].takeProfitPrice,Dig(sourceOrders[i].symbol)),
                (int)sourceOrders[i].openTime,
                (int)sourceOrders[i].openTimeGMT,
                (int)sourceOrders[i].expiration,
                (int)sourceOrders[i].expirationGMT,
                sourceOrders[i].comment,
                sourceOrders[i].sourceTicket,
                DoubleToString(sourceOrders[i].sourceLots,lotSizeDigits),
                (int)sourceOrders[i].sourceType,
                DoubleToString(sourceOrders[i].originalLots,lotSizeDigits),
                sourceOrders[i].originalTicket,
                DoubleToString(sourceOrders[i].sourceOriginalLots,lotSizeDigits),
                sourceOrders[i].sourceOriginalTicket
               );
     }
   FileClose(fH);
   if(cancel)
      return(false);
   CommentLabelText(8,"");
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetSourceOrdersFromFile()
  {
   if(IsTesting())
      return(false);
   if(!FileIsExist(sourceOrdersFile,FILE_COMMON))
      return(false);
   int fH=0,i,ct=0;
   string symbol,str;
   bool cancel=false;
   if((fH=FileOpen(sourceOrdersFile,FILE_COMMON|FILE_READ|FILE_SHARE_READ|FILE_CSV|FILE_ANSI,"\t"))==INVALID_HANDLE)
      return(false);
   sizeSourceOrders=0;
   ArrayResize(sourceOrders,0,10);
   while(!FileIsEnding(fH))
     {
      i=sizeSourceOrders;
      ct++;
      ArrayResize(sourceOrders,sizeSourceOrders+1,10);
      str=FileReadString(fH);
      if((symbol=ConvertSymbol(str))=="")
        {
         CommentLabelText(8,"Cannot Recognize "+str+". Check Broker Symbol Prefix/Suffix");
         cancel=true;
         break;
        }
      sourceOrders[i].symbol=symbol;
      sourceOrders[i].lots=(double)FileReadString(fH);
      sourceOrders[i].ticket=(int)FileReadString(fH);
      sourceOrders[i].direction=(int)FileReadString(fH);
      sourceOrders[i].type=(ENUM_ORDER_TYPE)FileReadString(fH);
      sourceOrders[i].magic=(int)FileReadString(fH);
      sourceOrders[i].openPrice=(double)FileReadString(fH);
      sourceOrders[i].stopLossPrice=(double)FileReadString(fH);
      sourceOrders[i].takeProfitPrice=(double)FileReadString(fH);
      sourceOrders[i].openTime=(datetime)((int)FileReadString(fH));
      sourceOrders[i].openTimeGMT=(datetime)((int)FileReadString(fH));
      sourceOrders[i].expiration=(datetime)((int)FileReadString(fH));
      sourceOrders[i].expirationGMT=(datetime)((int)FileReadString(fH));
      sourceOrders[i].comment=FileReadString(fH);
      sourceOrders[i].sourceTicket=(int)FileReadString(fH);
      sourceOrders[i].sourceLots=(double)FileReadString(fH);
      sourceOrders[i].sourceType=(ENUM_ORDER_TYPE)FileReadString(fH);
      sourceOrders[i].originalLots=(double)FileReadString(fH);
      sourceOrders[i].originalTicket=(int)FileReadString(fH);
      sourceOrders[i].sourceOriginalLots=(double)FileReadString(fH);
      sourceOrders[i].sourceOriginalTicket=(int)FileReadString(fH);
      sizeSourceOrders++;
     }
   FileClose(fH);
   if(cancel)
      return(false);
   CommentLabelText(8,"");
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SourceOrdersChanged()
  {
   bool changed=false;
   int i;
   if(sizeSourceOrders!=sizeLastSourceOrders)
      changed=true;
   else
      for(i=0; i<sizeSourceOrders; i++)
        {
         if(sourceOrders[i].ticket!=lastSourceOrders[i].ticket
            || sourceOrders[i].stopLossPrice!=lastSourceOrders[i].stopLossPrice
            || sourceOrders[i].takeProfitPrice!=lastSourceOrders[i].takeProfitPrice
            || sourceOrders[i].lots!=lastSourceOrders[i].lots
            || sourceOrders[i].expirationGMT!=lastSourceOrders[i].expirationGMT
            || sourceOrders[i].openPrice!=lastSourceOrders[i].openPrice
           )
           {
            changed=true;
            break;
           }
        }
   return(changed);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetSourceOrders()
  {
   int i;
   ArrayResize(lastSourceOrders,sizeSourceOrders,10);
   sizeLastSourceOrders=sizeSourceOrders;
   for(i=0; i<sizeSourceOrders; i++)
      lastSourceOrders[i]=sourceOrders[i];
   sizeSourceOrders=0;
   ArrayResize(sourceOrders,0,10);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CreateDestinationOrdersFile()
  {
   int fH,lotSizeDigits,i;
   if(sizeDestinationOrders==0)
     {
      if(FileIsExist(destinationOrdersFile,FILE_COMMON))
         FileDelete(destinationOrdersFile,FILE_COMMON);
      return(true);
     }
   if((fH=FileOpen(destinationOrdersFile,FILE_COMMON|FILE_WRITE|FILE_CSV|FILE_ANSI,"\t"))==INVALID_HANDLE)
      return(false);
   for(i=0; i<sizeDestinationOrders; i++)
     {
      lotSizeDigits=LotSizeDigits(destinationOrders[i].symbol);
      FileWrite(fH,
                destinationOrders[i].symbol,
                DoubleToString(destinationOrders[i].lots,lotSizeDigits),
                destinationOrders[i].ticket,
                destinationOrders[i].direction,
                (int)destinationOrders[i].type,
                destinationOrders[i].magic,
                DoubleToString(destinationOrders[i].openPrice,Dig(destinationOrders[i].symbol)),
                DoubleToString(destinationOrders[i].stopLossPrice,Dig(destinationOrders[i].symbol)),
                DoubleToString(destinationOrders[i].takeProfitPrice,Dig(destinationOrders[i].symbol)),
                (int)destinationOrders[i].openTime,
                (int)destinationOrders[i].openTimeGMT,
                (int)destinationOrders[i].expiration,
                (int)destinationOrders[i].expirationGMT,
                destinationOrders[i].comment,
                destinationOrders[i].sourceTicket,
                DoubleToString(destinationOrders[i].sourceLots,lotSizeDigits),
                (int)destinationOrders[i].sourceType,
                DoubleToString(destinationOrders[i].originalLots,lotSizeDigits),
                destinationOrders[i].originalTicket,
                DoubleToString(destinationOrders[i].sourceOriginalLots,lotSizeDigits),
                destinationOrders[i].sourceOriginalTicket
               );
     }
   FileClose(fH);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetDestinationOrdersFromFile()
  {
   sizeDestinationOrders=0;
   ArrayResize(destinationOrders,0,10);
   if(!FileIsExist(destinationOrdersFile,FILE_COMMON))
      return(true);
   int fH=0,i,ct=0;
   string symbol,str;
   bool cancel=false;
   if((fH=FileOpen(destinationOrdersFile,FILE_COMMON|FILE_READ|FILE_SHARE_READ|FILE_CSV|FILE_ANSI,"\t"))==INVALID_HANDLE)
      return(false);
   while(!FileIsEnding(fH))
     {
      i=sizeDestinationOrders;
      ct++;
      ArrayResize(destinationOrders,sizeDestinationOrders+1,10);
      str=FileReadString(fH);
      if((symbol=ConvertSymbol(str))=="")
        {
         CommentLabelText(8,"Cannot Recognize "+str+". Check Broker Symbol Prefix/Suffix");
         cancel=true;
         break;
        }
      destinationOrders[i].symbol=symbol;
      destinationOrders[i].lots=(double)FileReadString(fH);
      destinationOrders[i].ticket=(int)FileReadString(fH);
      destinationOrders[i].direction=(int)FileReadString(fH);
      destinationOrders[i].type=(ENUM_ORDER_TYPE)FileReadString(fH);
      destinationOrders[i].magic=(int)FileReadString(fH);
      destinationOrders[i].openPrice=(double)FileReadString(fH);
      destinationOrders[i].stopLossPrice=(double)FileReadString(fH);
      destinationOrders[i].takeProfitPrice=(double)FileReadString(fH);
      destinationOrders[i].openTime=(datetime)((int)FileReadString(fH));
      destinationOrders[i].openTimeGMT=(datetime)((int)FileReadString(fH));
      destinationOrders[i].expiration=(datetime)((int)FileReadString(fH));
      destinationOrders[i].expirationGMT=(datetime)((int)FileReadString(fH));
      destinationOrders[i].comment=FileReadString(fH);
      destinationOrders[i].sourceTicket=(int)FileReadString(fH);
      destinationOrders[i].sourceLots=(double)FileReadString(fH);
      destinationOrders[i].sourceType=(ENUM_ORDER_TYPE)FileReadString(fH);
      destinationOrders[i].originalLots=(double)FileReadString(fH);
      destinationOrders[i].originalTicket=(int)FileReadString(fH);
      destinationOrders[i].sourceOriginalLots=(double)FileReadString(fH);
      destinationOrders[i].sourceOriginalTicket=(int)FileReadString(fH);
      sizeDestinationOrders++;
     }
   FileClose(fH);
   if(cancel)
      return(false);
   CommentLabelText(8,"");
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ModifyDestinationOrder(ulong ticket,int sourceI,int destinationI) { return(AddDestinationOrder(ticket,sourceI,destinationI)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AddDestinationOrder(ulong ticket,int sourceI,int destinationI=-1)
  {
   if(ticket<0)
      return(false);
   int i,direction=0;
   ENUM_ORDER_TYPE orderType;
   if(destinationI<0)
     {
      i=sizeDestinationOrders;
      sizeDestinationOrders++;
      ArrayResize(destinationOrders,sizeDestinationOrders,10);
     }
   else
      i=destinationI;
   if(OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES))
     {
      if((orderType=(ENUM_ORDER_TYPE)OrderType())==OP_BUY || orderType==OP_BUYSTOP || orderType==OP_BUYLIMIT)
         direction=1;
      else
         if(orderType==OP_SELL || orderType==OP_SELLSTOP || orderType==OP_SELLLIMIT)
            direction=-1;
      destinationOrders[i].symbol=OrderSymbol();
      destinationOrders[i].lots=OrderLots();
      destinationOrders[i].ticket=OrderTicket();
      destinationOrders[i].direction=direction;
      destinationOrders[i].type=(ENUM_ORDER_TYPE)orderType;
      destinationOrders[i].magic=OrderMagicNumber();
      destinationOrders[i].openPrice=OrderOpenPrice();
      destinationOrders[i].stopLossPrice=OrderStopLoss();
      destinationOrders[i].takeProfitPrice=OrderTakeProfit();
      destinationOrders[i].openTime=OrderOpenTime();
      destinationOrders[i].openTimeGMT=ConvertServerTimeToGMT(OrderOpenTime());
      destinationOrders[i].expiration=OrderExpiration();
      destinationOrders[i].expirationGMT=ConvertServerTimeToGMT(OrderExpiration());
      destinationOrders[i].comment=OrderComment();
     }
   else
     {
      destinationOrders[i].symbol=sourceOrders[sourceI].symbol;
      destinationOrders[i].lots=0;
      destinationOrders[i].ticket=ticket;
      destinationOrders[i].direction=(invertTradeCopyDirection==1 ? -1 : 1)*sourceOrders[sourceI].direction;
      destinationOrders[i].type=(invertTradeCopyDirection==1 ? InvertType(sourceOrders[sourceI].type) : sourceOrders[sourceI].type);
      destinationOrders[i].magic=0;
      destinationOrders[i].openPrice=0;
      destinationOrders[i].stopLossPrice=0;
      destinationOrders[i].takeProfitPrice=0;
      destinationOrders[i].openTime=0;
      destinationOrders[i].openTimeGMT=0;
      destinationOrders[i].expiration=0;
      destinationOrders[i].expirationGMT=0;
      destinationOrders[i].comment="";
     }
   destinationOrders[i].sourceTicket=sourceOrders[sourceI].ticket;
   destinationOrders[i].sourceLots=sourceOrders[sourceI].lots;
   destinationOrders[i].sourceType=sourceOrders[sourceI].type;
   if(destinationI<0)
     {
      destinationOrders[i].originalLots=destinationOrders[i].lots;
      destinationOrders[i].originalTicket=ticket;
     }
   destinationOrders[i].sourceOriginalLots=sourceOrders[sourceI].originalLots;
   destinationOrders[i].sourceOriginalTicket=sourceOrders[sourceI].originalTicket;
   if(!CreateDestinationOrdersFile())
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RemoveDestinationOrder(ulong ticket)
  {
   if(ticket<0 || sizeDestinationOrders<=0)
      return(false);
   int i,j;
   orderStruct orders[]= {};
   ArrayResize(orders,sizeDestinationOrders);
   for(i=0; i<sizeDestinationOrders; i++)
      orders[i]=destinationOrders[i];
   ArrayResize(destinationOrders,0);
   j=0;
   for(i=0; i<sizeDestinationOrders; i++)
      if(orders[i].ticket!=ticket)
        {
         ArrayResize(destinationOrders,j+1,10);
         destinationOrders[j]=orders[i];
         j++;
        }
   sizeDestinationOrders=j;
   if(!CreateDestinationOrdersFile())
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE InvertType(ENUM_ORDER_TYPE type)
  {
   if(type==OP_BUY)
      return(OP_SELL);
   if(type==OP_SELL)
      return(OP_BUY);
   if(type==OP_BUYSTOP)
      return(OP_SELLSTOP);
   if(type==OP_SELLSTOP)
      return(OP_BUYSTOP);
   if(type==OP_BUYLIMIT)
      return(OP_SELLLIMIT);
   if(type==OP_SELLLIMIT)
      return(OP_BUYLIMIT);
   return(-1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ClosedAccountProfitToday(bool reset=false)
  {
   static int lastHistoryTotal=-1;
   static double lastClosedAccountProfitToday=0;
   static datetime lastClosedAccountProfitTodayDate=0;
   if(reset)
     {
      lastHistoryTotal=-1;
      lastClosedAccountProfitToday=0;
      lastClosedAccountProfitTodayDate=0;
      return(-1);
     }
   int historyTotal=OrdersHistoryTotal(),i;
   datetime today=StringToTime(TimeToString(TimeCurrent(),TIME_DATE)+" 00:00");
   if(lastHistoryTotal==historyTotal && lastClosedAccountProfitTodayDate>0 && lastClosedAccountProfitTodayDate==today)
      return (lastClosedAccountProfitToday);
   double netProfit=0;
   for(i=0; i<historyTotal; i++)
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) && OrderCloseTime()>=today && (OrderType()==OP_BUY || OrderType()==OP_SELL))
         netProfit+=OrderProfit()+OrderCommission()+OrderSwap();
   lastHistoryTotal=historyTotal;
   lastClosedAccountProfitToday=netProfit;
   lastClosedAccountProfitTodayDate=today;
   return(netProfit);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SendAlert(string msg)
  {
   if(ApplyMessageLog)
     {
      if(alertSound==1)
         PlaySound("alert.wav");
      if(alertPopup==1)
         Alert(msg);
      else
         Print(msg);
      if(alertEmail==1)
         SendMail(msg,msg);
      if(alertMobile==1)
         SendNotification(msg);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetOrdersTotal()
  {
   int ordersTotal=OrdersTotal(),er;
   if(ordersTotal>0)
      return(ordersTotal);
   ResetLastError();
   if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
      return(-1);
   if((er=GetLastError())>1 && er!=4051)
     {
      EPrint("GetOrdersTotal OrderSelect Error #"+IntegerToString(er)+" "+ErrorDescription(er)+" orderI:0 ordersTotal:0");
      return(-1);
     }
   return(ordersTotal);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotSizeByRisk(string symbol,int sLPoints,bool includeMarginRequired=true)
  {
   log1="";
   if(lotSizeRiskPercent==0)
      return (0);
   double sLossValue1Lot=DollarsPerPoint(symbol)*(double)sLPoints,lots,margin1Lot=(includeMarginRequired ? Margin1Lot(symbol) : 0),riskValue=AccountBalance()*lotSizeRiskPercent/100.0;
   if(riskValue==0 || sLossValue1Lot==0)
      return(0);
   lots=LotStepFloor(riskValue/(sLossValue1Lot+margin1Lot),symbol);
   log1=symbol+" Balance:$"+DoubleToString(AccountBalance(),2)+" Risk %:"+DoubleToString(lotSizeRiskPercent,2)+" Risk $:"+DoubleToString(riskValue,2)+" SL Points:"+(string)sLPoints+" $/Point 1 Lot:$"+DoubleToString(DollarsPerPoint(symbol),2)+(includeMarginRequired ? " Margin $ 1 Lot:$"+DoubleToString(margin1Lot,2) : "")+" Lots:"+(string)(riskValue/(sLossValue1Lot+margin1Lot))+" Rounded:"+(string)lots;
   return (lots);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Margin1Lot(string symbol)
  {
   if(symbol=="")
      symbol=Symbol();
   return (MarketInfo(symbol,MODE_MARGINREQUIRED));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DollarsPerPoint(string symbol,double lot=1.0)
  {
   if(symbol=="")
      symbol=Symbol();
   double pointValue=MarketInfo(symbol,MODE_TICKVALUE)*lot;
   if(pointValue==0)
      pointValue=lot*1.0;
   return pointValue;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DollarsPerPip(string symbol,double lot=1.0)
  {
   if(symbol=="")
      symbol=Symbol();
   double pipValue=DollarsPerPoint(symbol,lot)*(double)PipsToPoints(symbol);
   return pipValue;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PointSize(string symbol)
  {
   if(symbol=="")
      symbol=Symbol();
   return (MarketInfo(symbol,MODE_TICKSIZE));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int PipsToPoints(string symbol,double pips=1.0)
  {
   if(symbol=="")
      symbol=Symbol();
   int points=(int)MathRound(pips*MathPow(10,Dig(symbol)-BaseDigits(symbol)));
   return(points);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TradeAllowed(string symbol)
  {
   if(symbol=="")
      return(false);
   return ((bool)MarketInfo(symbol,MODE_TRADEALLOWED));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Dig(string symbol)
  {
   if(symbol=="")
      symbol=Symbol();
   return (int)MarketInfo(symbol,MODE_DIGITS);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int BaseDigits(string symbol)
  {
   if(symbol=="")
      symbol=Symbol();
   int dig=Dig(symbol),base=4;
   string s=symbol;
   StringToUpper(s);
   if(StringSubstr(s,0,1)==".")
      s=StringSubstr(s,1);
   if(dig<=1 || StringFind(s,"INDEX",0)>=0)
      base=0;
   else
      if(dig<=3)
         base=2;
   return(base);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CurrentBid(string symbol)
  {
   if(symbol=="")
      return(0);
   return (MarketInfo(symbol,MODE_BID));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CurrentAsk(string symbol)
  {
   if(symbol=="")
      return(0);
   return (MarketInfo(symbol,MODE_ASK));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ValidLotSize(string symbol,double lot)
  {
   if(minLotSize>0 && lot<minLotSize)
     {
      ermsg="Lot: "+(string)lot+" below Minimum Lot Size: "+(string)minLotSize;
      return(false);
     }
   if(maxLotSize>0 && lot>maxLotSize)
     {
      ermsg="Lot: "+(string)lot+" above Maximum Lot Size: "+(string)maxLotSize;
      return(false);
     }
   if(lot<=0 || lot<MarketInfo(symbol,MODE_MINLOT) || lot>MarketInfo(symbol,MODE_MAXLOT) || LotStepFloor(lot,symbol)!=lot)
     {
      ermsg="Min:"+(string)MarketInfo(symbol,MODE_MINLOT)+" Max:"+(string)MarketInfo(symbol,MODE_MAXLOT)+" Step:"+(string)MarketInfo(symbol,MODE_LOTSTEP);
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotStepFloor(double lot,string symbol)
  {
   if(symbol=="")
      return(0);
   double symbolLotStep=MarketInfo(symbol,MODE_LOTSTEP);
   if(symbolLotStep==0)
      return(lot);
   lot=NormalizeDouble(MathFloor(NormalizeDouble(lot/symbolLotStep,LotSizeDigits(symbol)))*symbolLotStep,LotSizeDigits(symbol));
   return(lot);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int LotSizeDigits(string symbol)
  {
   if(symbol=="")
      symbol=Symbol();
   string step=(string)MarketInfo(symbol,MODE_LOTSTEP);
   int len;
   while(StringSubstr(step,(len=StringLen(step))-1,1)=="0")
      step=StringSubstr(step,0,len-1);
   len=(StringLen(step)-2);
   if(len<0)
      len=0;
   return(len);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ConvertSymbol(string s)
  {
   string a;
   if(CurrentBid(a=s)>0)
      return(a);
   if(symbolSuffix!="" && CurrentBid(a=s+symbolSuffix)>0)
      return(a);
   if(symbolPrefix!="" && CurrentBid(a=symbolPrefix+StringSubstr(s,0,6))>0)
      return(a);
   if(symbolSuffix!="" && symbolPrefix!="" && CurrentBid(a=symbolPrefix+StringSubstr(s,0,6)+symbolSuffix)>0)
      return(a);
   if(CurrentBid(a=StringSubstr(s,0,6))>0)
      return(a);
   if(CurrentBid(a=StringSubstr(s,1,7))>0)
      return(a);
   return("");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string NormalizeSymbol(string s)
  {
   int len,lenS;
   if(symbolSuffix!="")
     {
      len=StringLen(symbolSuffix);
      lenS=StringLen(s);
      if(StringSubstr(s,lenS-len)==symbolSuffix)
         s=StringSubstr(s,0,lenS-len);
     }
   if(symbolPrefix!="")
     {
      len=StringLen(symbolPrefix);
      if(StringSubstr(s,0,len)==symbolPrefix)
         s=StringSubstr(s,len);
     }
   return(s);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetCommentLabelText(int line)
  {
   string str=ObjectGetString(0,CommentLabelName(line),OBJPROP_TEXT);
   int er;
   if((er=GetLastError())>1)
      return("");
   if(str==NULL || str=="" || str=="Text")
      str="";
   return (str);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateCommentLabels(int lines=35)
  {
   int line;
   string name;
   for(line=1; line<=lines; line++)
     {
      LabelCreate(0,(name=CommentLabelName(line)),0,LabelX,LabelY+12*line-10,CORNER_RIGHT_UPPER,"",LabelFont,LabelFontSize,LabelColor,LabelAngle,LabelAnchor,LabelBack,LabelSelection,LabelHidden,LabelZOrder);
      LabelTextChange(0,name,"");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CommentLabelText(int line,string text="")
  {
   if(ApplyMessageLog)
     {
      string name=CommentLabelName(line);
      if(ObjectFind(0,name)<0)
         CreateCommentLabels();
      LabelTextChange(0,name,text);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DeleteCommentLabels(int lines=35)
  {
   int line;
   LPrint();
   for(line=1; line<=lines; line++)
      LabelDelete(0,CommentLabelName(line));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CommentLabelName(int line)
  {
   return(COMMENT_LABEL_NAME+" "+IntegerToString(line));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void EPrint(string txt)
  {
   if(IsRepeat(txt))
      return;
   if(ApplyMessageLog)
      Print(txt);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LPrint(string txt="")
  {
   if(ApplyMessageLog)
     {
      if(IsRepeat(txt))
         return;
      static string lastTxt="";
      if(lastTxt==txt)
         return;
      lastTxt=txt;
      if(txt=="")
         return;
      Print(txt);
      if(StringLen(txt)>126)
        {
         string txt1=StringSubstr(txt,0,63),txt2=StringSubstr(txt,63,63),txt3=StringSubstr(txt,126,63);
         LPrint2(txt3);
         LPrint2(txt2);
         LPrint2(txt1);
        }
      else
         if(StringLen(txt)>63)
           {
            string txt1=StringSubstr(txt,0,63),txt2=StringSubstr(txt,63);
            LPrint2(txt2);
            LPrint2(txt1);
           }
         else
            LPrint2(txt);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LPrint2(string txt="")
  {
   if(ApplyMessageLog)
     {
      int max=11,j;
      string str;
      for(j=25+max-2; j>=25; j--)
        {
         str=GetCommentLabelText(j);
         CommentLabelText(j+1,str);
        }
      CommentLabelText(25,txt);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsRepeat(string str,int secs=10)
  {
   static string ar1[]= {};
   static datetime last1[]= {};
   static int sz1=0;
   int i,sz2=0;
   datetime now=TimeLocal(),last2[]= {};
   string ar2[]= {};
   bool found=false;
   if(sz1>0)
     {
      for(i=0; i<sz1; i++)
         if((int)now-(int)last1[i]<=secs)
           {
            ArrayResize(ar2,sz2+1,10);
            ArrayResize(last2,sz2+1,10);
            ar2[sz2]=ar1[i];
            last2[sz2]=last1[i];
            sz2++;
           }
      if(sz2<sz1)
        {
         sz1=sz2;
         ArrayResize(ar1,sz1,10);
         ArrayResize(last1,sz1,10);
         for(i=0; i<sz1; i++)
           {
            ar1[i]=ar2[i];
            last1[i]=last2[i];
           }
        }
     }
   for(i=0; i<sz1; i++)
      if(ar1[i]==str)
        {
         found=true;
         break;
        }
   if(found)
     {
      last1[i]=now;
      return(true);
     }
   ArrayResize(ar1,sz1+1,10);
   ArrayResize(last1,sz1+1,10);
   ar1[sz1]=str;
   last1[sz1]=now;
   sz1++;
   return(false);
  }

//+------------------------------------------------------------------+
//| Create a text label                                              |
//+------------------------------------------------------------------+
int               LabelX=300;                // X-axis distance
int               LabelY=15;                // Y-axis distance
string            LabelFont="Arial";         // Font
int               LabelFontSize=7;          // Font size
double            LabelAngle=0.0;            // Slope angle in degrees
ENUM_ANCHOR_POINT LabelAnchor=ANCHOR_LEFT_UPPER; // Anchor type
bool              LabelBack=false;           // Background object
bool              LabelSelection=false;       // Highlight to move
bool              LabelHidden=true;          // Hidden in the object list
long              LabelZOrder=0;             // Priority for mouse click
bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               sub_window=0,             // subwindow index
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 string            text="",             // text
                 const string            font="Arial",             // font
                 const int               font_size=10,             // font size
                 const color             clr=clrRed,               // color
                 const double            angle=0.0,                // text slope
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=0)                // priority for mouse click
  {
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
      return(false);
   if(text=="")
      text=" ";
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }
//+------------------------------------------------------------------+
//| Change the object text                                           |
//+------------------------------------------------------------------+
bool LabelTextChange(const long   chart_ID=0,   // chart's ID
                     const string name="Label", // object name
                     string text="")  // text
  {
   if(ObjectFind(chart_ID,name)<0)
      return(false);
   if(text=="")
      text=" ";
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   return(true);
  }
//+------------------------------------------------------------------+
//| Move the text label                                              |
//+------------------------------------------------------------------+
bool LabelMove(const long   chart_ID=0,   // chart's ID
               const string name="Label", // label name
               const int    x=0,          // X coordinate
               const int    y=0)          // Y coordinate
  {
   if(ObjectFind(chart_ID,name)<0)
      return(false);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   return(true);
  }

//+------------------------------------------------------------------+
//| Delete a text label                                              |
//+------------------------------------------------------------------+
bool LabelDelete(const long   chart_ID=0,   // chart's ID
                 const string name="Label") // label name
  {
   if(ObjectFind(chart_ID,name)<0)
      return(false);
   if(!ObjectDelete(chart_ID,name))
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartBackColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_BACKGROUND,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartForegroundColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_FOREGROUND,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartGridColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_GRID,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartBarUpColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_CHART_UP,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartBarDownColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_CHART_DOWN,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartBullCandleColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_CANDLE_BULL,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartBearCandleColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_CANDLE_BEAR,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartLineColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_CHART_LINE,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartVolumesColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_VOLUME,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartAskColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_ASK,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartStopLevelColorSet(const color clr,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_COLOR_STOP_LEVEL,clr)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartShiftSet(bool on=true,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_SHIFT,on)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartAutoScrollSet(bool on=true,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_AUTOSCROLL,on)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartScaleSet(const long val=2,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_SCALE,val)); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartCandlesModeSet(const long val=1,const long chart_ID=0) { return (ChartSetInteger(chart_ID,CHART_MODE,val)); }
bool ChartShiftPercentSet(const double val=26,const long chart_ID=0) { return (ChartSetDouble(chart_ID,CHART_SHIFT_SIZE,val)); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ChartSettings(string set="OldLace")
  {
   if(set=="OldLace")
     {
      ChartBackColorSet(clrOldLace);
      ChartForegroundColorSet(clrBlack);
      ChartShiftSet(true);
      ChartShiftPercentSet(38);
      ChartAutoScrollSet(true);
      ChartScaleSet(2);
      ChartGridColorSet(clrLightGray);
      ChartBarUpColorSet(clrRoyalBlue);
      ChartBarDownColorSet(clrFireBrick);
      ChartBullCandleColorSet(clrDodgerBlue);
      ChartBearCandleColorSet(clrRed);
      ChartLineColorSet(clrLime);
      ChartVolumesColorSet(clrLimeGreen);
      ChartAskColorSet(clrRed);
      ChartStopLevelColorSet(clrRed);
      ChartCandlesModeSet(CHART_CANDLES);
     }
   else
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSummerDST(string winterTZ,string summerTZ)
  {
   bool is;
   datetime t=(datetime)((int)TimeGMT()+(int)MathRound(GMTOffsetByTimeZone(summerTZ)*3600.0));
   if(winterTZ=="EET" && summerTZ=="EEST")
      is=IsSummerDST_Nth(t,3,SUNDAY,-1,"03:00",10,SUNDAY,-1,"04:00");
   else
      if(winterTZ=="EETX" && summerTZ=="EESTX")
         is=IsSummerDST_Nth(t,3,SUNDAY,2,"09:00",11,SUNDAY,1,"09:00");
      else
         if(winterTZ=="AEST" && summerTZ=="AEDT")
            is=IsSummerDST_Nth(t,10,SUNDAY,1,"02:00",4,SUNDAY,1,"03:00");
         else
            if(winterTZ=="EST" && summerTZ=="EDT")
               is=IsSummerDST_Nth(t,3,SUNDAY,2,"02:00",11,SUNDAY,1,"02:00");
            else
               if(winterTZ=="JST" && summerTZ=="JST")
                  is=true;
               else
                  is=IsSummerDST_Nth(t);
   return(is);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsEDT() { return(IsSummerDST("EST","EDT")); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSummerDST_Nth(datetime t,int summerStartMonth=3,int summerStartDay=SUNDAY,int summerStartDayNth=-1,string summerStartTime="03:00",int summerEndMonth=10,int summerEndDay=SUNDAY,int summerEndDayNth=-1,string summerEndTime="04:00")
  {
   int month,year,day,foundDays=0,startDay=1,endDay=31,incDay=1;
   bool is=false;
   datetime t2;
   if(t==0)
      t=TimeCurrent();
   month=TimeMonth(t);
   year=TimeYear(t);
   if(month==summerStartMonth)    // Summer DST
     {
      if(summerStartDayNth<0)
        {
         startDay=31;
         endDay=1;
         incDay=-1;
         summerStartDayNth*=-1;
        }
      for(day=startDay; incDay*day<=incDay*endDay; day=day+incDay)
        {
         t2=StrToTime(IntegerToString(year)+"."+IntegerToString(summerStartMonth)+"."+IntegerToString(day)+" "+summerStartTime); // Summer DST Begins 2 a.m. (Second Sunday in March)
         if(incDay<0 && TimeDay(t2)!=day)
            continue;
         if(t2>t)
           {
            is=false;
            break;
           }
         if(TimeDayOfWeek(t2)==summerStartDay)
            foundDays++;
         if(foundDays==summerStartDayNth)
           {
            is=true;
            break;
           }
        }
     }
   else
      if(month==summerEndMonth)
        {
         if(summerEndDayNth<0)
           {
            startDay=31;
            endDay=1;
            incDay=-1;
            summerEndDayNth*=-1;
           }
         for(day=startDay; incDay*day<=incDay*endDay; day=day+incDay)
           {
            t2=StrToTime(IntegerToString(year)+"."+IntegerToString(summerEndMonth)+"."+IntegerToString(day)+" "+summerEndTime); // Summer DST Ends 2 a.m. (First Sunday in November)
            if(incDay<0 && TimeDay(t2)!=day)
               continue;
            if(t2>t)
              {
               is=true;
               break;
              }
            if(TimeDayOfWeek(t2)==summerEndDay)
               foundDays++;
            if(foundDays==summerStartDayNth)
              {
               is=false;
               break;
              }
           }
        }
      else
         if(month<summerStartMonth || month>summerEndMonth)
            is=false;
         else
            is=true;
   return(is);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GMTOffsetByTimeZone(string z)
  {
   double o=0;
   if(z=="EET")
      o=2;
   else
      if(z=="EEST")
         o=3;
      else
         if(z=="AEST")
            o=10;
         else
            if(z=="AEDT")
               o=11;
            else
               if(z=="EETX")
                  o=2;
               else
                  if(z=="EESTX")
                     o=3;
                  else
                     if(z=="EDT")
                        o=-4;
                     else
                        if(z=="EST")
                           o=-5;
                        else
                           if(z=="JST")
                              o=9;
   return(o);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TimeZoneFromCode(int code)
  {
   if(code==1)
      return("EEST");
   if(code==2)
      return("EET");
   if(code==3)
      return("AEST");
   if(code==4)
      return("AEDT");
   if(code==5)
      return("EST");
   if(code==6)
      return("EDT");
   if(code==7)
      return("JST");
   return("");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime ConvertServerTimeToGMT(datetime serverTime)
  {
   if(serverTime==0)
      return(0);
   return (datetime)((int)serverTime-(int)MathRound(ServerGMTOffset()*3600.0));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime ConvertGMTToServerTime(datetime gMTTime)
  {
   if(gMTTime==0)
      return(0);
   return (datetime)((int)gMTTime+(int)MathRound(ServerGMTOffset()*3600.0));
  }
double ServerGMTOffset() { return(GMTOffsetByTimeZone(IsSummerDST(winterTimeZone,summerTimeZone) ? summerTimeZone : winterTimeZone)); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OriginalPartialClose(int orderI,ulong &originalTicket,double &originalLots)
  {
   string comment=OrderComment();
   originalTicket=OrderTicket();
   originalLots=OrderLots();
   if(StringSubstr(comment,0,6)!="from #")
      return(0);
   int i=0,num=0,max=0;
   while(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
     {
      i++;
      if(!IsClosedOrder() || StringSubstr(OrderComment(),0,4)!="to #" || (int)StringSubstr(OrderComment(),4)!=originalTicket)
         continue;
      num++;
      originalTicket=OrderTicket();
      originalLots+=OrderLots();
      if(max>0 && num>=max)
         break;
      i=0;
     }
   if(!OrderSelect(orderI,SELECT_BY_POS,MODE_TRADES))
      return(-1);
   return(num);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong TicketAfterPartialClose(ulong orderTicket)
  {
   if(!OrderSelect((int)orderTicket,SELECT_BY_TICKET,MODE_HISTORY) || OrderCloseTime()==0)
      return (0);
   string comment=OrderComment();
   if(StringSubstr(comment,0,4)!="to #")
      return(0);
   ulong ticket=(int)StringSubstr(comment,4);
   return(ticket);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsOpenOrder()
  {
   ENUM_TIMEFRAMES orderType=(ENUM_TIMEFRAMES)OrderType();
   if((orderType!=OP_BUY && orderType!=OP_SELL) || OrderCloseTime()!=0)
      return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsClosedOrder(datetime closedAfter=0)
  {
   ENUM_TIMEFRAMES orderType=(ENUM_TIMEFRAMES)OrderType();
   if((orderType!=OP_BUY && orderType!=OP_SELL) || OrderCloseTime()==0 || (closedAfter>0 && OrderCloseTime()<closedAfter))
      return(false);
   return(true);
  }


//get filtering symbol tokenize
int get_symbol_token(string strSymbols)
  {
   string sep=";";                // A separator as a character
   ushort u_sep;                  // The code of the separator character
//string result[];               // An array to get strings
//--- Get the separator code
   u_sep=StringGetCharacter(sep,0);
//--- Split the string to substrings
   int k=0;
   k=StringSplit(strSymbols,u_sep,symbols);
   return k;
  }
//+------------------------------------------------------------------+
