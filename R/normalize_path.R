#' Check if the script is running in a container.
#'
#' @returns A truthy value indicating the state.
is_running_in_docker <- function() {
  dockerenv_exists <- file.exists("/.dockerenv")
  cgroup_exists <- file.exists("/proc/1/cgroup")
  in_container_runtime <- FALSE
  if (cgroup_exists) {
    in_container_runtime <- any(
      grepl("docker", readLines("/proc/1/cgroup", warn = FALSE))
    )
  }
  return(dockerenv_exists || in_container_runtime)
}

#' Gets the absolute path of a file.
#'
#' @param path a normalized, absolute path.
#' @return The absolute host path, if it exists.
#' @export
absolute_path_mapper <- function(path) {
  return(normalizePath(path, mustWork = FALSE))
}

#' Normalizes a path
#'
#' @param path The path to normalize.
#' @param path_mappers The mappers to be utilized to normalize the path.
#' @returns The normalized path.
#' @export
normalize_path <- function(path, path_mappers = c()) {
  path_mappers <- c(
    absolute_path_mapper, # Adds absolute_path_mapper at the beginning.
    path_mappers
  )
  for (mapper in path_mappers) {
    path <- mapper(path)
  }
  return(path)
}

#' Maps a path to host volumes.
#'
#' @param path a normalized, absolute path.
#' @return The absolute host path, if it exists.
#' @export
docker_mount_mapper <- function(path) {
  if (!is_running_in_docker()) {
    return(path)
  }

  # Since we are running in docker, we can use our hostname as an heuristic
  # to obtain our id.
  # TODO: Check if this assumption is right for other container engines and
  #       generalize this implementation.
  hostname <- Sys.info()["nodename"]
  output <- system2("docker",
    args = paste("inspect -f '{{ json .Mounts }}'", hostname),
    stdout = TRUE,
  )
  parsed_output <- jsonlite::fromJSON(output)

  # Iterate over mounts, return first match.
  for (i in seq_len(nrow(parsed_output))) {
    destination <- parsed_output[i, ]$Destination
    if (startsWith(path, destination)) {
      source <- parsed_output[i, ]$Source
      path <- sub(destination, source, path)
      return(path)
    }
  }
  return(path)
}
