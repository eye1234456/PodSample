#!/usr/bin/ruby
require 'xcodeproj'
require "FileUtils"
# 遍历删除文件夹

##########步骤一：解析framework##############
def create_header_impl(basePath,framework_name)
    # 添加.h .m文件 如下
    project_dir = "#{basePath}/#{framework_name}"
    source_dir = "#{project_dir}/#{framework_name}"
    old_framework_header_dir = "#{basePath}/#{framework_name}.framework/Headers"
    puts "basePath: #{basePath}"
    puts "project_dir: #{project_dir}"
    puts "source_dir: #{source_dir}"
    puts "old_framework_header_dir: #{old_framework_header_dir}"

    # 清空旧数据
    if File.directory?(project_dir) && Dir.exist?(project_dir)
        FileUtils.rm_rf(project_dir)
    end
    # 创建项目文件
    FileUtils.mkdir_p(project_dir)
    # 创建项目源文件
    FileUtils.mkdir_p(source_dir)
    ####################
    Dir.foreach(old_framework_header_dir) { |file_path| 
        new_header_file_path = File.join(source_dir, File.basename(file_path))
        
        # 复制文件
        if file_path.end_with?(".h") 
            old_header = "#{old_framework_header_dir}/#{file_path}"
            puts "old header : #{file_path}"
            puts "new header : #{new_header_file_path}"
            FileUtils.cp(old_header, new_header_file_path)
        end
        
    }
end

##########步骤二：生成xcodeproj及相关文件（核心！！！！！）##############
def auto_create_project(old_framework_path)
    # puts "================="
    # 添加.h .m文件 如下
    basePath = File.dirname(old_framework_path) #当前根路径
    framework_name = File.basename(old_framework_path, ".*")  #=> "TTTPlayerKit"
    project_name = framework_name
    project_dir = "#{basePath}/#{project_name}"
    source_dir = "#{project_dir}/#{project_name}"
    project_path = "#{project_dir}/#{project_name}.xcodeproj"
    old_framework_header_dir = "#{old_framework_path}/Headers"
    puts "project_dir: #{project_dir}"
    puts "source_dir: #{source_dir}"
    puts "project_path: #{project_path}"
    puts "old_framework_header_dir: #{old_framework_header_dir}"
    
    ####################
    # 创建project类
    if File.exist?(project_path) 
        # 已经存在就打开
        puts "already exists #{project_path}, open"
        project = Xcodeproj::Project.open(project_path)
    else
        # 不存在就创建
        puts "not exists #{project_path}, need create"
        project = Xcodeproj::Project.new(project_path)
    end

    # 获取target
    if project.targets.size > 0 && project.targets.include?(project_name) 
        # 已经存在了，则是打开一个文件
        puts "already exists target #{project_name}, get"
        target = project.targets.select do |t|
            t == project_name
        end
    else
    # 不存在，就创建
    puts "not exists target #{project_name}, need create"
    target = project.new_target(:framework, project_name, :ios, "9.0")
    end


    # 创建group
    #找到要插入的group (参数中true表示如果找不到group，就创建一个group)
    groupName = project_name
    group = project.main_group.find_subpath(File.join(groupName),true)
    #set一下sorce_tree
    # group.set_source_tree('SOURCE_ROOT')
    group.set_source_tree('SOURCE_ROOT')

    # 需要天机的文件路径

    # puts header_arr
    Dir.foreach(source_dir) do |file_path|
        
        header_file_path = "#{source_dir}/#{file_path}"
        if header_file_path.end_with?(".h") 
            file_ref = group.new_file(header_file_path)
            # 要加到Headers public里,framework特有
            header = target.headers_build_phase.add_file_reference(file_ref)
            # 设置访问权限为'public', 这样导出的framework才可以访问到
            header.settings = { 'ATTRIBUTES' => ['Public'] }
        elsif header_file_path.end_with?(".m")
            # .m文件要加到项目里去
            file_ref = group.new_file(header_file_path)
            target.source_build_phase.add_file_reference(file_ref, true)
        end

    end
    # 保存
    project.save()
end

##########步骤三：生成xcarchive##############
def auto_make_archive(base_path, project_scheme_name, configuration)
   
   # 项目路径
    project_dir_path = "#{base_path}/#{project_scheme_name}"
    # FileUtils.cd(project_dir_path)
    # .xcodeproj路径
    xcodeproj_path = "#{project_dir_path}/#{project_scheme_name}.xcodeproj"
    # 临时存放文件的文件夹名字
    temp_archive_folder_name = "#{project_scheme_name}_#{project_scheme_name}_XCFramework"
    temp_archive_folder_path = "#{project_dir_path}/#{temp_archive_folder_name}/simulator.xcarchive"
   
    # set path for iOS device archive
    # 删除之前生成的xcframework的文件夹
    # 创建临时文件
    FileUtils.rm_rf(temp_archive_folder_path)
    FileUtils.mkdir_p(temp_archive_folder_path)
        
    # 创建simulator的framework
    sh_archive = %/
        xcodebuild archive \
        -project "#{xcodeproj_path}" \
        -scheme "#{project_scheme_name}" \
        -configuration "#{configuration}" \
        -destination="iOS Simulator" \
        -archivePath "#{temp_archive_folder_path}" \
        -sdk iphonesimulator clean build \
        SKIP_INSTALL=NO \
        BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
    /
    puts sh_archive
    exec(sh_archive)

end

##########步骤四：导出合并xcframework##############
def auto_combine_framework(base_path, project_scheme_name, configuration)
    # 生成xcframework
    project_dir_path = "#{base_path}/#{project_scheme_name}"
    temp_archive_folder_name = "#{project_scheme_name}_#{project_scheme_name}_XCFramework"
    # 生成的xcframework
    
    export_dir_path = "#{base_path}/export"
    # 生成xcframework的路劲
    export_xcframework_path = "#{export_dir_path}/#{project_scheme_name}.xcframework"
    # 生成真机、模拟器二和一的路劲
    export_mix_framework_path = "#{export_dir_path}/#{project_scheme_name}.framework"

    # 创建导出文件地址
    FileUtils.rm_rf(export_dir_path)
    FileUtils.mkdir_p(export_dir_path)

    # set path for iOS simulator archive
    # 生成的模拟器的库的文件
    simulator_archive_path = "#{project_dir_path}/#{temp_archive_folder_name}/simulator.xcarchive"
    simulator_framework_path = "#{simulator_archive_path}/Products/Library/Frameworks/#{project_scheme_name}.framework"
    iphone_framework_path = "#{base_path}/#{project_scheme_name}.framework"

    sh_xcframework = %/
    xcodebuild -create-xcframework \
    -framework #{simulator_framework_path} \
    -framework #{iphone_framework_path} \
    -output "#{export_xcframework_path}"
    /
    puts sh_xcframework
    exec(sh_xcframework)
    # 生成真机模拟器二合一framework
    

    # 先复制一个真机的版本到目标
    # sh_mix_framework = %/
    # cp -rf #{iphone_framework_path} #{export_mix_framework_path}\
    # lipo -create \
    # #{simulator_framework_path}/#{project_scheme_name} \
    # #{export_mix_framework_path}/#{project_scheme_name} \
    # -output #{export_mix_framework_path}/#{project_scheme_name}
    # /
    # exec(sh_mix_framework)
    exec("open #{export_dir_path}")
end

##########整合调用##############
def create_framework_project(old_framework_path)
    basePath = File.dirname(old_framework_path) #当前根路径
    framework_name = File.basename(old_framework_path, ".*")
    puts "old_framework_path: #{old_framework_path}"
    puts "basePath: #{basePath}"
    puts "framework_name: #{framework_name}"
    # 1、解析旧的framework，并复制对应的文件
    create_header_impl(basePath,framework_name)
    # 2、创建项目
    auto_create_project(old_framework_path)
    # 3、生成xrchive
    # auto_make_archive(basePath, framework_name, "Debug")
    # 4、合并成xcframework
    # auto_combine_framework(basePath, framework_name, "Debug")
    # exec("sh #{basePath}/archive_tool_auto.sh")
end

old_framework_path = "/xxx/xxx/AAA.framework"
create_framework_project(old_framework_path)
