class Ftools
  # Returns enumerator for every single file og directory in a given path.
  def self.foreach_r(args)
    if !args.key?(:files) or args[:files]
      files = true
    else
      files = false
    end
    
    if !args.key?(:dirs) or args[:dirs]
      dirs = true
    else
      dirs = false
    end
    
    raise Errno::ENOENT if !File.exists?(args[:path])
    
    Enumerator.new do |y|
      if !File.directory?(args[:path]) or File.symlink?(args[:path])
        if args[:fpath]
          y << File.realpath(args[:path])
        else
          y << File.basename(args[:path])
        end
      else
        Dir.foreach(args[:path]) do |file|
          next if file == "." or file == ".."
          fpath = "#{args[:path]}/#{file}"
          next if args.key?(:ignore) and args[:ignore].index(fpath) != nil
          
          if args[:fpath]
            obj = fpath
          else
            obj = file
          end
          
          if !File.directory?(fpath)
            y << obj if files
          else
            y << obj if dirs
            
            Ftools.foreach_r(args.merge(:path => fpath)).each do |file|
              y << file
            end
          end
        end
      end
    end
  end
  
  #Clones ownership and permissions from one path to another.
  def self.clone_perms(args)
    perms = Ftools.perms(args[:path_f])
    File.chmod(perms.to_i(8), args[:path_t])
  end
  
  #Returns the octal file-permissions for a given path.
  def self.perms(path)
    mode = File.stat(path).mode
    perms = sprintf("%o", mode)[-4, 4]
    return perms
  end
  
  #Clones the from-path to to to-path. Also symlinks!
  def self.clone(args)
    if File.symlink?(args[:path_f])
      File.symlink(File.readlink(args[:path_f]), args[:path_t])
    elsif File.directory?(args[:path_f])
      Dir.mkdir(args[:path_t], Ftools.perms(args[:path_f]).to_i(8)) if !File.exists?(args[:path_t])
    else
      File.open(args[:path_t], "wb") do |fp_w|
        File.open(args[:path_f], "rb") do |fp_r|
          begin
            while read = fp_r.sysread(4096)
              fp_w.write(read)
            end
          rescue EOFError
            #ignore.
          end
        end
      end
      
      Ftools.clone_perms(:path_f => args[:path_f], :path_t => args[:path_t])
    end
  end
end