#!/usr/bin/env python3
"""Regenerate the dependency-free Xcode project. Run from repository root."""
from pathlib import Path
import hashlib, json
root=Path(__file__).resolve().parents[1]
objects={}
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def q(s): return json.dumps(str(s))
def add(name,isa,body):
 i=uid(name); objects[i]=f'isa = {isa}; {body}'; return i
def ref(name,path,typ,tree='<group>'):
 return add(name,'PBXFileReference',f'lastKnownFileType = {typ}; path = {q(path)}; sourceTree = {q(tree)};')
def arr(ids): return '('+','.join(ids)+',)'
files={}
groups=[]
for folder,ext,typ in [('Sources','*.swift','sourcecode.swift'),('Tests','*.swift','sourcecode.swift'),('UITests','*.swift','sourcecode.swift'),('Configuration','*','text')]:
 ids=[]
 for path in sorted((root/folder).glob(ext)):
  if path.is_file() and not path.name.endswith('.local.xcconfig'):
   f=ref(str(path.relative_to(root)),path.name,typ); files[str(path.relative_to(root))]=f;ids.append(f)
 groups.append(add(folder,'PBXGroup',f'children = {arr(ids)}; path = {q(folder)}; sourceTree = "<group>";'))
libraryFolder=ref('pictureFolder','Resources/Pictures','folder')
licenseFile=ref('mulberryLicense','Resources/Mulberry-LICENSE.txt','text')
attributionFile=ref('mulberryAttribution','Resources/Mulberry-ATTRIBUTION.txt','text')
groups.extend([libraryFolder,licenseFile,attributionFile])
assets=ref('assets','Assets.xcassets','folder.assetcatalog')
groups.append(assets)
products=[]
configs=['Debug','Release','CloudDebug','CloudRelease']
appID=uid('appTarget')
proxy=add('testProxy','PBXContainerItemProxy',f'containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {appID}; remoteInfo = SophiaAAC;')
dependency=add('testDependency','PBXTargetDependency',f'target = {appID}; targetProxy = {proxy};')
targets=[]
for key,folder,name,productType in [('app','Sources','SophiaAAC','application'),('test','Tests','SophiaAACTests','bundle.unit-test'),('ui','UITests','SophiaAACUITests','bundle.ui-testing')]:
 builds=[]
 for path,f in files.items():
  if path.startswith(folder+'/'): builds.append(add('build'+path,'PBXBuildFile',f'fileRef = {f};'))
 sources=add(key+'sources','PBXSourcesBuildPhase',f'buildActionMask = 2147483647; files = {arr(builds)}; runOnlyForDeploymentPostprocessing = 0;')
 resources=[]
 if key=='app': resources=[add('libraryBuild','PBXBuildFile',f'fileRef = {libraryFolder};'),add('licenseBuild','PBXBuildFile',f'fileRef = {licenseFile};'),add('attributionBuild','PBXBuildFile',f'fileRef = {attributionFile};'),add('assetBuild','PBXBuildFile',f'fileRef = {assets};'), add('privacyBuild','PBXBuildFile',f'fileRef = {files["Configuration/PrivacyInfo.xcprivacy"]};')]
 resourcePhase=add(key+'resources','PBXResourcesBuildPhase',f'buildActionMask = 2147483647; files = {arr(resources) if resources else "()"}; runOnlyForDeploymentPostprocessing = 0;')
 frameworkPhase=add(key+'frameworks','PBXFrameworksBuildPhase','buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
 ext='app' if key=='app' else 'xctest'
 prod=add(key+'product','PBXFileReference',f'explicitFileType = {"wrapper.application" if key=="app" else "wrapper.cfbundle"}; includeInIndex = 0; path = {name}.{ext}; sourceTree = BUILT_PRODUCTS_DIR;')
 products.append(prod)
 cfgs=[]
 for cfg in configs:
  debug=cfg.endswith('Debug')
  settings={'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if debug else '-O','SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG $(inherited)' if debug else '$(inherited)','DEBUG_INFORMATION_FORMAT':'dwarf' if debug else 'dwarf-with-dsym'}
  base=''
  if key=='app':
   base=f'baseConfigurationReference = {files["Configuration/Cloud.xcconfig" if cfg.startswith("Cloud") else "Configuration/Local.xcconfig"]};'
   settings['ENABLE_TESTABILITY']='YES' if debug else 'NO'
  else:
   settings.update({'PRODUCT_NAME':name,'PRODUCT_BUNDLE_IDENTIFIER':'com.nujoom.'+name,'GENERATE_INFOPLIST_FILE':'YES','IPHONEOS_DEPLOYMENT_TARGET':'17.0','TARGETED_DEVICE_FAMILY':'2','SWIFT_VERSION':'5.0','CODE_SIGN_STYLE':'Automatic','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator'})
   if key=='test': settings.update({'TEST_HOST':'$(BUILT_PRODUCTS_DIR)/SophiaAAC.app/SophiaAAC','BUNDLE_LOADER':'$(TEST_HOST)'})
   else: settings['TEST_TARGET_NAME']='SophiaAAC'
  cfgs.append(add(key+cfg,'XCBuildConfiguration',base+'buildSettings = {'+''.join(q(k)+' = '+q(v)+';' for k,v in settings.items())+'}; name = '+q(cfg)+';'))
 cfglist=add(key+'configs','XCConfigurationList',f'buildConfigurations = {arr(cfgs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
 phases=[sources,frameworkPhase,resourcePhase]
 if key=='app':
  guard=add('releaseGuard','PBXShellScriptBuildPhase','buildActionMask = 2147483647; files = (); inputPaths = (); outputPaths = (); runOnlyForDeploymentPostprocessing = 0; shellPath = /bin/sh; shellScript = '+q('/bin/sh \"${SRCROOT}/Scripts/check-release.sh\"')+'; alwaysOutOfDate = 1; name = \"Check release readiness\";')
  phases.insert(0,guard)
 targets.append(add(key+'Target','PBXNativeTarget',f'buildConfigurationList = {cfglist}; buildPhases = {arr(phases)}; buildRules = (); dependencies = {"()" if key=="app" else arr([dependency])}; name = {name}; productName = {name}; productReference = {prod}; productType = "com.apple.product-type.{productType}";'))
productGroup=add('products','PBXGroup',f'children = {arr(products)}; name = Products; sourceTree = "<group>";')
mainGroup=add('main','PBXGroup',f'children = {arr(groups+[productGroup])}; sourceTree = "<group>";')
projectConfigs=[]
for cfg in configs:
 settings={'SDKROOT':'iphoneos','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','ALWAYS_SEARCH_USER_PATHS':'NO'}
 projectConfigs.append(add('project'+cfg,'XCBuildConfiguration','buildSettings = {'+''.join(q(k)+' = '+q(v)+';' for k,v in settings.items())+'}; name = '+q(cfg)+';'))
projectCfg=add('projectConfigs','XCConfigurationList',f'buildConfigurations = {arr(projectConfigs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
project=add('project','PBXProject',f'attributes = {{LastUpgradeCheck = 2630; TargetAttributes = {{{appID} = {{CreatedOnToolsVersion = 26.3;}};}};}}; buildConfigurationList = {projectCfg}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base,); mainGroup = {mainGroup}; productRefGroup = {productGroup}; projectDirPath = ""; projectRoot = ""; targets = {arr(targets)};')
projectDir=root/'Sophia-AAC.xcodeproj'
projectDir.mkdir(exist_ok=True)
(projectDir/'project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+''.join(i+' = {'+body+'};\n' for i,body in objects.items())+'}; rootObject = '+project+';}\n')
schemes=projectDir/'xcshareddata'/'xcschemes';schemes.mkdir(parents=True,exist_ok=True)
def buildref(key,name,ext):
 return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(key+"Target")}" BuildableName="{name}.{ext}" BlueprintName="{name}" ReferencedContainer="container:Sophia-AAC.xcodeproj"/>'
app=buildref('app','SophiaAAC','app')
for name,prefix in [('Sophia-AAC',''),('Sophia-AAC iCloud','Cloud')]:
 xml=f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2630" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="{prefix}Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>
<TestableReference skipped="NO">{buildref('test','SophiaAACTests','xctest')}</TestableReference>
<TestableReference skipped="NO">{buildref('ui','SophiaAACUITests','xctest')}</TestableReference>
</Testables></TestAction>
<LaunchAction buildConfiguration="{prefix}Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="{prefix}Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="{prefix}Debug"/><ArchiveAction buildConfiguration="{prefix}Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
 (schemes/(name+'.xcscheme')).write_text(xml)
print('Generated Sophia-AAC.xcodeproj with local and iCloud schemes.')
