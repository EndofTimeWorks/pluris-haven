package works.endoftime.plurishaven;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;

public final class ExportSourceValidatorTest {
    @Rule
    public final TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Test
    public void acceptsExportDirectlyInsideCache() throws Exception {
        File cache = temporaryFolder.newFolder("cache");
        File staging = new File(cache, "pluris-haven-export-direct");
        assertTrue(staging.mkdir());
        File source = new File(staging, "archive.pluris");
        assertTrue(source.createNewFile());

        assertTrue(ExportSourceValidator.isOwned(source, cache));
    }

    @Test
    public void acceptsExportInsideNestedSystemTempDirectory() throws Exception {
        File cache = temporaryFolder.newFolder("cache");
        File systemTemp = new File(cache, "data");
        assertTrue(systemTemp.mkdir());
        File staging = new File(systemTemp, "pluris-haven-export-nested");
        assertTrue(staging.mkdir());
        File source = new File(staging, "archive.pluris");
        assertTrue(source.createNewFile());

        assertTrue(ExportSourceValidator.isOwned(source, cache));
    }

    @Test
    public void rejectsExportOutsideCache() throws Exception {
        File cache = temporaryFolder.newFolder("cache");
        File outside = temporaryFolder.newFolder("outside");
        File staging = new File(outside, "pluris-haven-export-external");
        assertTrue(staging.mkdir());
        File source = new File(staging, "archive.pluris");
        assertTrue(source.createNewFile());

        assertFalse(ExportSourceValidator.isOwned(source, cache));
    }

    @Test
    public void rejectsWrongDirectoryPrefixAndMissingFiles() throws Exception {
        File cache = temporaryFolder.newFolder("cache");
        File staging = new File(cache, "other-export-directory");
        assertTrue(staging.mkdir());
        File source = new File(staging, "archive.pluris");
        assertTrue(source.createNewFile());

        assertFalse(ExportSourceValidator.isOwned(source, cache));
        assertFalse(ExportSourceValidator.isOwned(new File(staging, "missing.pluris"), cache));
    }

    @Test
    public void rejectsSymlinkThatEscapesCache() throws Exception {
        File cache = temporaryFolder.newFolder("cache");
        File staging = new File(cache, "pluris-haven-export-linked");
        assertTrue(staging.mkdir());
        File outside = temporaryFolder.newFolder("outside");
        Path outsideSource = new File(outside, "archive.pluris").toPath();
        Files.write(outsideSource, new byte[] {1});
        Path link = new File(staging, "archive.pluris").toPath();
        Files.createSymbolicLink(link, outsideSource);

        assertFalse(ExportSourceValidator.isOwned(link.toFile(), cache));
    }
}
