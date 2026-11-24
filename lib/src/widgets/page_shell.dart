part of '../../main.dart';

class PageShell extends StatelessWidget{final String title,subtitle;final Widget child;const PageShell({super.key,required this.title,required this.subtitle,required this.child});@override Widget build(BuildContext c)=>Column(children:[BrandHeader(),Padding(padding:const EdgeInsets.fromLTRB(18,4,18,12),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),Text(subtitle,style:const TextStyle(color:muted,fontSize:11))]))])),Expanded(child:child)]);}
